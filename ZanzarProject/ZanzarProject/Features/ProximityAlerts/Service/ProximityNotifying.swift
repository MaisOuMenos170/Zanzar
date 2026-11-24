import Foundation

/// Shows a proximity alert to the user. The real one posts a local notification.
protocol ProximityNotifying: AnyObject {
    /// Whether the user allowed notifications at all.
    func canPost() async -> Bool
    func post(_ content: ProximityAlertContent) async throws
}
