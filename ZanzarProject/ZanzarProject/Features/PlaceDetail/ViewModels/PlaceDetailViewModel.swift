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
    private let savedPlaces: SavedPlacesServicing
    private let openingReminders: OpeningReminderScheduling
    private let pendingCheckIns: PendingCheckInQueue
    private var loadGeneration = 0
    /// One id per place for every try of the check-in, so a retry after a lost answer is a replay, not a 409.
    private let checkInMutationID = UUID().uuidString
    /// When the user first confirmed this check-in: kept across retries, and sent with it if it has to wait.
    private var checkInStartedAt: Date?
    /// The position that was verified when the network failed, so the check-in can be kept as it was.
    private var offlineCoordinate: UserCoordinate?

    var detail: PlaceDetail?
    /// Photos users sent; loaded after the detail and never blocking it.
    private(set) var userPhotos: [PlacePhoto] = []
    var isLoading = false
    var isCheckingIn = false
    var errorMessage: String?
    var showsCellularImagesPrompt = false
    var showsCheckInConfirmation = false
    var checkInWarning: CheckInWarning?
    /// "Você já passou por aqui": tapped on the done button, or the server answered 409.
    var showsAlreadyCheckedInAlert = false
    /// A reminder for the moment the place opens is scheduled.
    private(set) var hasOpeningReminder = false
    var earnedSealPresentation: EarnedSealPresentation?
    var showsCompletedItineraryAlert = false
    /// Whether the user bookmarked this place.
    private(set) var isSaved = false
    private var isUpdatingSaved = false
    private var pendingCompletedItineraryAlert = false

    init(
        place: MapPlace,
        userIDProvider: @escaping @Sendable () -> String? = { AuthTokenStore.shared.userID },
        userCoordinateProvider: @escaping @Sendable () async throws -> UserCoordinate = {
            try await LocationMapService.shared.currentUserLocation()
        },
        service: PlaceDetailServicing = PlaceDetailService(),
        pendingRatingStore: PendingRatingStoring? = nil,
        savedPlaces: SavedPlacesServicing = SavedPlacesService(),
        openingReminders: OpeningReminderScheduling? = nil,
        pendingCheckIns: PendingCheckInQueue? = nil
    ) {
        self.place = place
        self.userIDProvider = userIDProvider
        self.userCoordinateProvider = userCoordinateProvider
        self.service = service
        self.pendingRatingStore = pendingRatingStore ?? UserDefaultsPendingRatingStore()
        self.savedPlaces = savedPlaces
        self.openingReminders = openingReminders ?? UserNotificationOpeningReminderScheduler()
        self.pendingCheckIns = pendingCheckIns ?? .shared
    }

    /// Whether this place has a check-in waiting for the network (and the server does not know it yet).
    var isCheckInPending: Bool {
        guard let detail else { return false }
        return !detail.hasCheckedIn && pendingCheckIns.contains(placeID: detail.id)
    }

    /// "Check-in feito em 26/11/2026 às 14:20." (without the time when the server did not say).
    var alreadyCheckedInMessage: String {
        guard let date = detail?.checkedInAt else { return L10n.string("placeDetail.alreadyCheckedIn.message") }
        return L10n.string(
            "placeDetail.alreadyCheckedIn.messageWithDate",
            date.formatted(date: .numeric, time: .omitted),
            date.formatted(date: .omitted, time: .shortened)
        )
    }

    func showAlreadyCheckedIn() {
        guard detail?.hasCheckedIn == true else { return }
        showsAlreadyCheckedInAlert = true
    }

    enum ReminderOutcome: Equatable {
        case scheduled
        case cancelled
        case permissionDenied
        case failed
    }

    func loadReminderState() async {
        guard let detail, detail.opensAt != nil else { return }
        hasOpeningReminder = await openingReminders.isScheduled(placeID: detail.id)
    }

    /// Schedules the reminder for the opening time, or cancels it when it is already there.
    func toggleOpeningReminder() async -> ReminderOutcome? {
        guard let detail, let opensAt = detail.opensAt else { return nil }
        if hasOpeningReminder {
            await openingReminders.cancel(placeID: detail.id)
            hasOpeningReminder = false
            return .cancelled
        }
        do {
            let allowed = try await openingReminders.schedule(
                placeID: detail.id,
                placeName: detail.displayName,
                at: opensAt
            )
            guard allowed else { return .permissionDenied }
            hasOpeningReminder = true
            return .scheduled
        } catch {
            AppLog.placeDetail.error("Failed to schedule the opening reminder placeId=\(detail.id)", error: error)
            return .failed
        }
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

    enum SaveOutcome: Equatable {
        case saved
        case removed
        case failed(message: String)
    }

    @discardableResult
    func toggleSaved() async -> SaveOutcome? {
        guard let userID = userIDProvider(), !isUpdatingSaved else { return nil }
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
            NotificationCenter.default.post(name: AppNotification.savedPlacesDidChange, object: nil)
            return wasSaved ? .removed : .saved
        } catch is CancellationError {
            isSaved = wasSaved
            return nil
        } catch {
            isSaved = wasSaved
            AppLog.placeDetail.error("Failed to update saved place placeId=\(place.id)", error: error)
            if case APIError.httpStatus(409, _) = error {
                return .failed(message: L10n.string("placeDetail.saveButton.limitReached"))
            }
            return .failed(message: APIError.rateLimitedMessage(for: error)
                ?? L10n.string("placeDetail.saveButton.failedToast"))
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
            await loadReminderState()
        } catch is CancellationError {
            return
        } catch {
            guard generation == loadGeneration else { return }
            errorMessage = APIError.displayMessage(for: error, fallback: L10n.string("error.generic.message"))
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

    /// Asks to check in. The position is checked first, so someone who is too far (or whose position is unknown
    /// or too coarse) hears it right away instead of confirming and only then being told.
    func requestCheckIn() async {
        guard let detail, !detail.hasCheckedIn, !isCheckingIn else { return }
        isCheckingIn = true
        errorMessage = nil
        checkInWarning = nil
        defer { isCheckingIn = false }
        guard await verifiedCheckInCoordinate(for: detail) != nil else { return }
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
        let startedAt = checkInStartedAt ?? Date()
        checkInStartedAt = startedAt

        do {
            let result = try await service.checkIn(
                placeID: currentDetail.id,
                coordinate: coordinate,
                mutationID: checkInMutationID,
                datetime: startedAt
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
            showsAlreadyCheckedInAlert = true
        } catch APIError.httpStatus(422, _) {
            checkInWarning = .tooFar
        } catch let error where error.isOffline {
            offlineCoordinate = coordinate
            checkInWarning = .offline
        } catch {
            errorMessage = APIError.displayMessage(for: error, fallback: L10n.string("error.generic.message"))
        }
    }

    /// "Guardar e enviar depois": keeps the check-in, as the user confirmed it, until the network is back.
    func keepCheckInForLater() {
        defer { checkInWarning = nil }
        guard let detail, let userID = userIDProvider(), let coordinate = offlineCoordinate else { return }
        pendingCheckIns.enqueue(
            PendingCheckIn(
                id: checkInMutationID,
                userID: userID,
                placeID: detail.id,
                placeName: detail.displayName,
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
                accuracyMeters: coordinate.accuracyMeters,
                checkedInAt: checkInStartedAt ?? Date()
            )
        )
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
