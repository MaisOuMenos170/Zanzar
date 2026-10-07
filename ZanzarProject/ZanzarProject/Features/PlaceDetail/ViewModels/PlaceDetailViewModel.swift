import Foundation
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
    private var loadGeneration = 0

    var detail: PlaceDetail?
    var isLoading = false
    var isCheckingIn = false
    var errorMessage: String?
    var showsCellularImagesPrompt = false
    var showsCheckInConfirmation = false
    var checkInWarning: CheckInWarning?
    var earnedSealPresentation: EarnedSealPresentation?
    var showsCompletedItineraryAlert = false
    private var pendingCompletedItineraryAlert = false

    init(
        place: MapPlace,
        userIDProvider: @escaping @Sendable () -> String? = { AuthTokenStore.shared.userID },
        userCoordinateProvider: @escaping @Sendable () async throws -> UserCoordinate = {
            try await LocationMapService().currentUserLocation()
        },
        service: PlaceDetailServicing = PlaceDetailService(),
        pendingRatingStore: PendingRatingStoring = UserDefaultsPendingRatingStore()
    ) {
        self.place = place
        self.userIDProvider = userIDProvider
        self.userCoordinateProvider = userCoordinateProvider
        self.service = service
        self.pendingRatingStore = pendingRatingStore
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
        } catch is CancellationError {
            return
        } catch {
            guard generation == loadGeneration else { return }
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
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

        let coordinate: UserCoordinate
        do {
            coordinate = try await userCoordinateProvider()
        } catch is CancellationError {
            return
        } catch {
            checkInWarning = .locationRequired
            return
        }

        switch CheckInPolicy.verdict(
            for: coordinate,
            placeLatitude: currentDetail.latitude,
            placeLongitude: currentDetail.longitude
        ) {
        case .tooFar:
            checkInWarning = .tooFar
            return
        case .uncertain:
            checkInWarning = .locationUncertain
            return
        case .allowed:
            break
        }

        do {
            let result = try await service.checkIn(placeID: currentDetail.id, coordinate: coordinate)
            applySuccessfulCheckIn(to: &currentDetail, result: result)
            detail = currentDetail
            queueRatingPrompt(for: currentDetail, userID: userID)
            presentEarnedSealIfNeeded(for: currentDetail, result: result)
            presentCompletedItineraryIfNeeded(result: result)
            notifyItineraryChangeIfNeeded(result: result)
        } catch is CancellationError {
            return
        } catch APIError.httpStatus(409, _) {
            currentDetail.hasCheckedIn = true
            detail = currentDetail
            queueRatingPrompt(for: currentDetail, userID: userID)
        } catch APIError.httpStatus(422, _) {
            checkInWarning = .tooFar
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func allowCellularImages() {
        PlaceMediaAccessPolicy.shared.allowsCellularImages = true
        showsCellularImagesPrompt = false
    }

    func updateCellularImagesPromptIfNeeded(using mediaPolicy: PlaceMediaAccessPolicy) {
        if mediaPolicy.needsCellularPermissionPrompt,
           detail?.heroPhotoReference != nil {
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
                checkedInAt: Date()
            )
        )
    }
}
