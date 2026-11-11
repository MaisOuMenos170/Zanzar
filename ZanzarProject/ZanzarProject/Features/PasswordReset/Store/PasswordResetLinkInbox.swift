import Foundation
import Observation

/// Receives the URLs the system hands to the app (`onOpenURL` in `MyApp`) and keeps the password reset link
/// until `ContentView` presents it.
@Observable
final class PasswordResetLinkInbox {
    var pending: PasswordResetLink?

    func receive(_ url: URL) {
        // The token is a credential: log only that a link arrived, never the URL.
        guard let link = PasswordResetLink(url: url) else {
            AppLog.passwordReset.warning("Ignored an incoming URL that is not a valid password reset link")
            return
        }
        AppLog.passwordReset.info("Password reset link received")
        pending = link
    }

    /// Hands the pending link over once and clears it, so the same link is not presented twice.
    func take() -> PasswordResetLink? {
        defer { pending = nil }
        return pending
    }
}
