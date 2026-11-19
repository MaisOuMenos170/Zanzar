import Foundation
import Observation

@Observable
final class BlockedProfilesViewModel {
    private(set) var blockedUsers: [BlockedUser] = []
    private(set) var isLoading = false
    private(set) var hasLoaded = false
    var errorMessage: String?

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
            blockedUsers = try await service.fetchBlockedUsers(userID: userID)
            errorMessage = nil
        } catch is CancellationError {
            return
        } catch {
            errorMessage = L10n.string("userPhotos.privacy.error.message")
        }
    }

    func unblock(_ user: BlockedUser) async {
        guard let userID = userIDProvider() else { return }
        do {
            try await service.unblock(user.id, userID: userID)
            blockedUsers.removeAll { $0.id == user.id }
        } catch is CancellationError {
            return
        } catch {
            errorMessage = L10n.string("userPhotos.privacy.error.message")
        }
    }
}
