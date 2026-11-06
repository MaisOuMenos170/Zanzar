import Observation

/// Keeps the signed-in user in the auth flow (avatar editor and passport) until onboarding is finished.
///
/// `ContentView` swaps to the main tabs as soon as the session is authenticated, so the flow that
/// creates the account must call `begin()` before signing in.
@MainActor
@Observable
final class OnboardingGate {
    private(set) var isActive = false
    /// Name of the account being created, from the registration response; `nil` after Sign in with Apple.
    var username: String?

    func begin() {
        isActive = true
    }

    func finish() {
        isActive = false
        username = nil
    }

    /// After Sign in with Apple the backend does not say whether the account is new, so a user without an
    /// avatar is treated as new. Call it once signed in, with the gate already begun. Returns `true` when the
    /// avatar editor should be shown; otherwise the gate is finished. A failed lookup never blocks the user.
    func resolveAfterSignIn(
        avatarService: AvatarServicing = AvatarService(),
        userID: String? = AuthTokenStore.shared.userID
    ) async -> Bool {
        guard let userID else {
            finish()
            return false
        }
        let hasNoAvatar: Bool
        do {
            hasNoAvatar = try await avatarService.fetchAvatar(userID: userID) == nil
        } catch {
            hasNoAvatar = false
        }
        if !hasNoAvatar {
            finish()
        }
        return hasNoAvatar
    }
}
