import Foundation
import UserNotifications

/// Lets the alerts show as a banner while the app is open (without it iOS would swallow them, and the daily
/// allowance would be spent on an alert nobody saw), and opens the place when the user taps one.
final class ProximityNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list]
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        guard response.actionIdentifier == UNNotificationDefaultActionIdentifier,
              let placeID = ProximityAlertRouter.placeID(from: response.notification.request.content.userInfo) else {
            return
        }
        await MainActor.run { ProximityAlertRouter.shared.open(placeID: placeID) }
    }
}
