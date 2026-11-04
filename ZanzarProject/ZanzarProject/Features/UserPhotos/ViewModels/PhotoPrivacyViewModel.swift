import Foundation
import Observation

/// "Photos and privacy": the terms text, the blocked users (with unblock) and the developer contact.
@Observable
final class PhotoPrivacyViewModel {
    private(set) var blockedUsers: [BlockedUser] = []
    private(set) var isLoading = false
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

    var supportEmail: String? { SupportContact.email }

    func load() async {
        guard let userID = userIDProvider() else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            blockedUsers = try await service.fetchBlockedUsers(userID: userID)
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
        } catch {
            errorMessage = L10n.string("userPhotos.privacy.error.message")
        }
    }
}
