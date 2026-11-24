import Foundation

/// Reads and asks for the system permissions behind proximity alerts. The real one talks to Core Location and
/// `UNUserNotificationCenter`.
protocol ProximityPermissionServicing: AnyObject {
    func status() async -> ProximityPermissionStatus
    func requestNotifications() async
    /// Takes the user from whatever they granted before up to "Always". Returns when they have answered.
    func requestAlwaysLocation() async
    func openSettings()
}
