import Foundation
import MapKit
import Observation

struct EarnedSealPresentation: Equatable, Sendable {
    let placeName: String
    let category: ZanzarPlaceCategory
}

@Observable
final class PlaceDetailViewModel {
    private let service: PlaceDetailServicing
    private let place: MapPlace
    private let userIDProvider: @Sendable () -> String?
    private let userCoordinateProvider: @Sendable () async throws -> UserCoordinate
    private let pendingRatingStore: PendingRatingStoring
    private let applePlaceLookup: ApplePlaceLookingUp
    private let savedPlaces: SavedPlacesServicing
    private var loadGeneration = 0
    /// One id per place for every try of the check-in, so a retry after a lost answer is a replay, not a 409.
    private let checkInMutationID = UUID().uuidString

    var detail: PlaceDetail?
    /// Photos users sent; loaded after the detail and never blocking it.
    private(set) var userPhotos: [PlacePhoto] = []
    var isLoading = false
    var isCheckingIn = false
    var errorMessage: String?
    var showsCellularImagesPrompt = false
    var showsCheckInConfirmation = false
    var checkInWarning: CheckInWarning?
    var earnedSealPresentation: EarnedSealPresentation?
    var showsCompletedItineraryAlert = false
    /// Whether the user bookmarked this place.
    private(set) var isSaved = false
    private var isUpdatingSaved = false
    private var pendingCompletedItineraryAlert = false
    /// The place in Apple Maps, for Apple's place card (its photos and reviews). `nil` until found.
    var applePlaceItem: MKMapItem?
    var isLookingUpApplePlace = false
    /// Apple Maps has no safe match for this place, so the card should not be offered.
    var applePlaceUnavailable = false

    init(
        place: MapPlace,
        userIDProvider: @escaping @Sendable () -> String? = { AuthTokenStore.shared.userID },
        userCoordinateProvider: @escaping @Sendable () async throws -> UserCoordinate = {
            try await LocationMapService.shared.currentUserLocation()
        },
        service: PlaceDetailServicing = PlaceDetailService(),
        pendingRatingStore: PendingRatingStoring? = nil,
        applePlaceLookup: ApplePlaceLookingUp? = nil,
        savedPlaces: SavedPlacesServicing = SavedPlacesService()
    ) {
        self.place = place
        self.userIDProvider = userIDProvider
        self.userCoordinateProvider = userCoordinateProvider
        self.service = service
        self.pendingRatingStore = pendingRatingStore ?? UserDefaultsPendingRatingStore()
        self.applePlaceLookup = applePlaceLookup ?? ApplePlaceLookupService.shared
        self.savedPlaces = savedPlaces
    }

    /// Whether the place is on the user's saved list. A failure leaves the bookmark empty: it must not hide the place.
    func loadSavedState() async {
        guard let userID = userIDProvider() else { return }
        do {
            isSaved = try await savedPlaces.savedPlaceIDs(userID: userID).contains(place.id)
        } catch is CancellationError {
            return
        } catch {
            AppLog.placeDetail.warning("Saved places unavailable placeId=\(place.id)")
        }
    }

    /// Flips the bookmark at once and puts it back if the backend refuses.
    func toggleSaved() async {
        guard let userID = userIDProvider(), !isUpdatingSaved else { return }
        isUpdatingSaved = true
        defer { isUpdatingSaved = false }

        let wasSaved = isSaved
        isSaved = !wasSaved
        do {
            if wasSaved {
                try await savedPlaces.remove(placeID: place.id, userID: userID)
            } else {
                try await savedPlaces.save(placeID: place.id, userID: userID)
            }
        } catch is CancellationError {
            isSaved = wasSaved
        } catch {
            isSaved = wasSaved
            AppLog.placeDetail.error("Failed to update saved place placeId=\(place.id)", error: error)
            if case APIError.httpStatus(409, _) = error {
                errorMessage = L10n.string("placeDetail.saveButton.limitReached")
            } else {
                errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            }
        }
    }

    /// Finds the place in Apple Maps so its card can show Apple's photos. Safe to call again: it does nothing
    /// once the place was found or ruled out, or while a search is running.
    func loadApplePlace() async {
        guard applePlaceItem == nil, !applePlaceUnavailable, !isLookingUpApplePlace else { return }
        isLookingUpApplePlace = true
        defer { isLookingUpApplePlace = false }

        do {
            if let item = try await applePlaceLookup.mapItem(for: place) {
                applePlaceItem = item
            } else {
                applePlaceUnavailable = true
            }
        } catch is CancellationError {
            return
        } catch {
            // A network failure is not "unavailable": a later call may still find the place.
            AppLog.placeDetail.error("Apple Maps place lookup failed", error: error)
        }
    }

    func load() async {
        loadGeneration += 1
        let generation = loadGeneration

        isLoading = true
        errorMessage = nil
        defer {
            if generation == loadGeneration {
                isLoading = false
            }
        }

        let userCoordinateTask = Task { try? await userCoordinateProvider() }

        do {
            let loadedDetail = try await service.fetchPlaceDetail(
                context: PlaceDetailLoadContext(
                    place: place,
                    userCoordinate: await userCoordinateTask.value,
                    userID: userIDProvider()
                )
            )
            guard generation == loadGeneration else { return }
            detail = loadedDetail
            await loadUserPhotos()
        } catch is CancellationError {
            return
        } catch {
            guard generation == loadGeneration else { return }
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    /// Curated photos first, then users' photos (see `PlacePhotoMixer`).
    var displayedPhotos: [PlacePhoto] {
        PlacePhotoMixer.mix(curated: detail?.photos ?? [], user: userPhotos, limit: PlaceDetail.maximumPhotoCount)
    }

    /// Reloads users' photos, e.g. after the user sent one. A failure keeps the curated photos on screen.
    func loadUserPhotos() async {
        do {
            userPhotos = try await service.fetchUserPhotos(placeID: place.id)
        } catch is CancellationError {
            return
        } catch {
            AppLog.placeDetail.warning("User photos unavailable placeId=\(place.id)")
        }
    }

    func requestCheckIn() {
        guard let detail, !detail.hasCheckedIn, !isCheckingIn else { return }
        showsCheckInConfirmation = true
    }

    func confirmCheckIn() async {
        showsCheckInConfirmation = false
        await performCheckIn()
    }

    func dismissEarnedSealAlert() {
        earnedSealPresentation = nil
        if pendingCompletedItineraryAlert {
            pendingCompletedItineraryAlert = false
            showsCompletedItineraryAlert = true
        }
    }

    func dismissCompletedItineraryAlert() {
        showsCompletedItineraryAlert = false
    }

    func performCheckIn() async {
        guard !isCheckingIn else { return }
        guard var currentDetail = detail, !currentDetail.hasCheckedIn else { return }
        guard let userID = userIDProvider() else {
            errorMessage = String(localized: "placeDetail.checkInError.notAuthenticated")
            return
        }

        isCheckingIn = true
        errorMessage = nil
        checkInWarning = nil
        defer { isCheckingIn = false }

        guard let coordinate = await verifiedCheckInCoordinate(for: currentDetail) else { return }

        do {
            let result = try await service.checkIn(
                placeID: currentDetail.id,
                coordinate: coordinate,
                mutationID: checkInMutationID
            )
            applySuccessfulCheckIn(to: &currentDetail, result: result)
            detail = currentDetail
            queueRatingPrompt(for: currentDetail, userID: userID)
            presentEarnedSealIfNeeded(for: currentDetail, result: result)
            presentCompletedItineraryIfNeeded(result: result)
            notifyItineraryChangeIfNeeded(result: result)
            NotificationCenter.default.post(name: AppNotification.checkInDidSucceed, object: nil)
        } catch is CancellationError {
            return
        } catch APIError.httpStatus(409, _) {
            currentDetail.hasCheckedIn = true
            detail = currentDetail
            queueRatingPrompt(for: currentDetail, userID: userID)
            NotificationCenter.default.post(name: AppNotification.checkInDidSucceed, object: nil)
        } catch APIError.httpStatus(422, _) {
            checkInWarning = .tooFar
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    /// The user's position when it is precise enough and close enough to check in; otherwise sets
    /// `checkInWarning` and returns `nil`.
    private func verifiedCheckInCoordinate(for detail: PlaceDetail) async -> UserCoordinate? {
        let coordinate: UserCoordinate
        do {
            coordinate = try await userCoordinateProvider()
        } catch is CancellationError {
            return nil
        } catch {
            checkInWarning = .locationRequired
            return nil
        }

        switch CheckInPolicy.verdict(
            for: coordinate,
            placeLatitude: detail.latitude,
            placeLongitude: detail.longitude
        ) {
        case .tooFar:
            checkInWarning = .tooFar
            return nil
        case .uncertain:
            checkInWarning = .locationUncertain
            return nil
        case .allowed:
            return coordinate
        }
    }

    func allowCellularImages() {
        PlaceMediaAccessPolicy.shared.allowsCellularImages = true
        showsCellularImagesPrompt = false
    }

    func updateCellularImagesPromptIfNeeded(using mediaPolicy: PlaceMediaAccessPolicy) {
        if mediaPolicy.needsCellularPermissionPrompt,
           detail?.photos.isEmpty == false {
            showsCellularImagesPrompt = true
        }
    }

    private func applySuccessfulCheckIn(to detail: inout PlaceDetail, result: CheckInResult) {
        detail.hasCheckedIn = true
        detail.totalCheckIns += 1
    }

    private func presentEarnedSealIfNeeded(for detail: PlaceDetail, result: CheckInResult) {
        guard result.isNewStamp else { return }
        let category = result.sealCategory ?? (detail.category == .unknown ? nil : detail.category)
        guard let category else { return }
        earnedSealPresentation = EarnedSealPresentation(placeName: detail.displayName, category: category)
    }

    private func presentCompletedItineraryIfNeeded(result: CheckInResult) {
        guard result.isItineraryCompleted else { return }
        if earnedSealPresentation != nil {
            pendingCompletedItineraryAlert = true
        } else {
            showsCompletedItineraryAlert = true
        }
    }

    private func notifyItineraryChangeIfNeeded(result: CheckInResult) {
        guard result.completedItinerarySlots != nil || result.isItineraryCompleted else { return }
        NotificationCenter.default.post(name: AppNotification.activeItineraryDidChange, object: nil)
    }

    private func queueRatingPrompt(for detail: PlaceDetail, userID: String) {
        pendingRatingStore.save(
            PendingRating(
                userID: userID,
                placeID: detail.id,
                placeName: detail.displayName,
                latitude: detail.latitude,
                longitude: detail.longitude,
                checkedInAt: Date(),
                categoryTitleKey: detail.category.titleKey
            )
        )
    }
}
