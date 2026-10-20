import Foundation

enum AppNotification {
    static let activeItineraryDidChange = Notification.Name("activeItineraryDidChange")
    /// A check-in was recorded (or found to exist already): profile stats and the map pins are outdated.
    static let checkInDidSucceed = Notification.Name("checkInDidSucceed")
}
