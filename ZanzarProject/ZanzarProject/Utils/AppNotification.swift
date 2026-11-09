import Foundation

enum AppNotification {
    static let activeItineraryDidChange = Notification.Name("activeItineraryDidChange")
    /// A check-in was recorded (or found to exist already): profile stats and the map pins are outdated.
    static let checkInDidSucceed = Notification.Name("checkInDidSucceed")
    /// The user just started a roteiro: a good moment to offer the proximity alerts.
    static let itineraryDidStart = Notification.Name("itineraryDidStart")
    /// The session ended because the tokens could no longer be refreshed; the user has to sign in again.
    static let sessionExpired = Notification.Name("sessionExpired")
}
