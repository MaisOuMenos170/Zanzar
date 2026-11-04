import Foundation
import Observation

/// The user's own photos with where each one stands, and deleting them.
@Observable
final class MyPhotosViewModel {
    private(set) var photos: [UserPhoto] = []
    private(set) var isLoading = false
    private(set) var hasLoaded = false
    var errorMessage: String?
    var photoPendingDeletion: UserPhoto?

    private let service: UserPhotosServicing
    private let userIDProvider: @Sendable () -> String?

    init(
        service: UserPhotosServicing = UserPhotosService(),
        userIDProvider: @escaping @Sendable () -> String? = { AuthTokenStore.shared.userID }
    ) {
        self.service = service
        self.userIDProvider = userIDProvider
    }

    func load() async {
        guard let userID = userIDProvider() else { return }
        isLoading = true
        defer {
            isLoading = false
            hasLoaded = true
        }
        do {
            photos = try await service.fetchMyPhotos(userID: userID)
            errorMessage = nil
        } catch is CancellationError {
            return
        } catch {
            errorMessage = APIError.rateLimitedMessage(for: error) ?? L10n.string("userPhotos.myPhotos.error.message")
        }
    }

    func confirmDeletion() async {
        guard let photo = photoPendingDeletion else { return }
        photoPendingDeletion = nil
        do {
            try await service.deletePhoto(photo.id, placeID: photo.placeID)
            photos.removeAll { $0.id == photo.id }
        } catch {
            errorMessage = L10n.string("userPhotos.myPhotos.deleteError.message")
        }
    }
}
