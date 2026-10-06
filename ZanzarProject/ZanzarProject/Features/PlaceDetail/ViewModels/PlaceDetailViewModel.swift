import Foundation
import Observation

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

    init(
        place: MapPlace,
        userIDProvider: @escaping @Sendable () -> String? = { AuthTokenStore.shared.getToken().flatMap(JWTDecoder.userID(from:)) },
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

    func performCheckIn() async {
        guard !isCheckingIn else { return }
        guard var currentDetail = detail, !currentDetail.hasCheckedIn else { return }
        guard let userID = userIDProvider() else {
            errorMessage = String(localized: "placeDetail.checkInError.notAuthenticated")
            return
        }

        isCheckingIn = true
        errorMessage = nil
        defer { isCheckingIn = false }

        do {
            try await service.checkIn(placeID: currentDetail.id)
            currentDetail.hasCheckedIn = true
            currentDetail.totalCheckIns += 1
            detail = currentDetail
            queueRatingPrompt(for: currentDetail, userID: userID)
        } catch is CancellationError {
            return
        } catch APIError.httpStatus(409, _) {
            // Already checked in (another device or session): still queue the prompt, since the inline
            // rating is gone from the detail. The map skips it if the user has already rated.
            currentDetail.hasCheckedIn = true
            detail = currentDetail
            queueRatingPrompt(for: currentDetail, userID: userID)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
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
}
