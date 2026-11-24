import SwiftUI

extension View {
    /// Reads `message` aloud to VoiceOver when this view appears and each time the message changes. An error or
    /// status line that shows up on its own never takes the VoiceOver cursor, so it has to be announced.
    func announced(_ message: String) -> some View {
        self
            .onAppear { AccessibilityNotification.Announcement(message).post() }
            .onChange(of: message) { _, new in AccessibilityNotification.Announcement(new).post() }
    }
}
