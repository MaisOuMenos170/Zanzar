import SwiftUI

/// Owns the transient message shown by `ToastOverlay`. It lives at the app root so any screen can raise a
/// toast without drawing it itself, and the toast can outlive the screen that raised it.
@MainActor
@Observable
final class ToastPresenter {
    private(set) var message: String?

    func show(_ message: String) {
        self.message = message
        // The overlay appears without moving focus, so VoiceOver has to be told about it.
        AccessibilityNotification.Announcement(message).post()
    }

    func dismiss() {
        message = nil
    }
}
