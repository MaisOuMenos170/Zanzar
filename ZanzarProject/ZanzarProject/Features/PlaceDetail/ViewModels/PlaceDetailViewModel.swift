import Foundation
import Observation

@Observable
final class PlaceDetailViewModel {
    private let service: PlaceDetailServicing
    private let place: MapPlace
    private let userIDProvider: @Sendable () -> String?

    var detail: PlaceDetail?
    var isLoading = false
    var isCheckingIn = false
    var isSubmittingReaction = false
    var errorMessage: String?
    var showsCellularImagesPrompt = false

    init(
        place: MapPlace,
        userIDProvider: @escaping @Sendable () -> String? = { AuthTokenStore.shared.getToken().flatMap(JWTDecoder.userID(from:)) },
        service: PlaceDetailServicing = PlaceDetailService()
    ) {
        self.place = place
        self.userIDProvider = userIDProvider
        self.service = service
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            detail = try await service.fetchPlaceDetail(
                context: PlaceDetailLoadContext(
                    place: place,
                    userID: userIDProvider()
                )
            )
        } catch is CancellationError {
            return
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func performCheckIn() async {
        guard var currentDetail = detail, !currentDetail.hasCheckedIn else { return }
        guard let userID = userIDProvider() else {
            errorMessage = String(localized: "placeDetail.checkInError.notAuthenticated")
            return
        }

        isCheckingIn = true
        errorMessage = nil
        defer { isCheckingIn = false }

        do {
            try await service.checkIn(placeID: currentDetail.id, userID: userID)
            currentDetail.hasCheckedIn = true
            currentDetail.totalCheckIns += 1
            detail = currentDetail
        } catch is CancellationError {
            return
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func selectReaction(_ impressionTag: String) async {
        guard var currentDetail = detail else { return }
        guard currentDetail.hasCheckedIn else {
            errorMessage = String(localized: "placeDetail.reactionError.checkInRequired")
            return
        }
        guard currentDetail.selectedReactionTag == nil else { return }
        guard let userID = userIDProvider() else {
            errorMessage = String(localized: "placeDetail.reactionError.notAuthenticated")
            return
        }

        isSubmittingReaction = true
        errorMessage = nil
        defer { isSubmittingReaction = false }

        do {
            try await service.submitReaction(
                placeID: currentDetail.id,
                userID: userID,
                impressionTag: impressionTag
            )

            currentDetail.reactions = currentDetail.reactions.map { reaction in
                var updated = reaction
                if updated.impressionTag == impressionTag {
                    updated.count += 1
                    updated.isSelected = true
                }
                return updated
            }
            currentDetail.selectedReactionTag = impressionTag
            detail = currentDetail
        } catch is CancellationError {
            return
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func allowCellularImages() {
        PlaceMediaAccessPolicy.shared.allowsCellularImages = true
        showsCellularImagesPrompt = false
    }
}
