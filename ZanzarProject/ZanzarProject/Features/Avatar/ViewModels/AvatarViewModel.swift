import Foundation
import Observation

@Observable
final class AvatarViewModel {
    private let service: AvatarServicing
    private let userIDProvider: @Sendable () -> String?
    private var loadGeneration = 0

    var avatar: Avatar?
    var isLoading = false
    var errorMessage: String?
    var hasNoAvatar = false
    var isCreating = false
    var createFailed = false

    init(
        service: AvatarServicing = AvatarService(),
        userIDProvider: @escaping @Sendable () -> String? = { AuthTokenStore.shared.userID }
    ) {
        self.service = service
        self.userIDProvider = userIDProvider
    }

    func createPlaceholderAvatar() async {
        guard !isCreating, let userID = userIDProvider() else { return }
        isCreating = true
        createFailed = false
        defer { isCreating = false }

        do {
            avatar = try await service.createAvatar(userID: userID, avatar: .placeholder)
            hasNoAvatar = false
        } catch is CancellationError {
            return
        } catch APIError.httpStatus(409, _) {
            await load()
        } catch {
            createFailed = true
        }
    }

    func load() async {
        loadGeneration += 1
        let generation = loadGeneration

        isLoading = true
        errorMessage = nil
        hasNoAvatar = false
        defer {
            if generation == loadGeneration {
                isLoading = false
            }
        }

        guard let userID = userIDProvider() else {
            avatar = nil
            errorMessage = L10n.string("avatar.loadError.notAuthenticated")
            return
        }

        do {
            let loaded = try await service.fetchAvatar(userID: userID)
            guard generation == loadGeneration else { return }
            avatar = loaded
            hasNoAvatar = loaded == nil
        } catch is CancellationError {
            return
        } catch {
            // The server's message is never shown: the service already logged the details.
            guard generation == loadGeneration else { return }
            errorMessage = APIError.rateLimitedMessage(for: error) ?? L10n.string("avatar.errorState.message")
        }
    }
}
