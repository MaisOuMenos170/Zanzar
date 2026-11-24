import Foundation
import UIKit

/// Registers for remote notifications so Zanzar can send re-engagement pushes
/// (inactivity nudges, unfinished itineraries, streaks). The device token is sent
/// to the backend once the user is authenticated. Taps on notifications are handled by
/// `ProximityNotificationDelegate`, the single `UNUserNotificationCenter` delegate.
final class AppDelegate: NSObject, UIApplicationDelegate {
    /// Called when APNs has assigned a device token to this app.
    nonisolated func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Task { @MainActor in
            await PushTokenManager.shared.register(deviceToken: deviceToken)
        }
    }

    nonisolated func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        AppLog.auth.error("Failed to register for remote notifications", error: error)
    }
}
