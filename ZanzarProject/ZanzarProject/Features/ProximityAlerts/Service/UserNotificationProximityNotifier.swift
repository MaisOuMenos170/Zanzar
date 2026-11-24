import Foundation
import UserNotifications

/// Posts the alerts as local notifications, right away. Nearby places are `passive` (they appear in Notification
/// Center without sound or waking the screen); the next stop of a roteiro is a normal notification.
final class UserNotificationProximityNotifier: ProximityNotifying {
    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func canPost() async -> Bool {
        switch await center.notificationSettings().authorizationStatus {
        case .authorized, .provisional, .ephemeral: true
        case .notDetermined, .denied: false
        @unknown default: false
        }
    }

    func post(_ content: ProximityAlertContent) async throws {
        let notification = UNMutableNotificationContent()
        notification.title = content.title
        notification.body = content.body
        notification.threadIdentifier = "proximity"
        notification.userInfo = ["placeID": content.placeID]
        notification.interruptionLevel = content.kind == .itineraryStop ? .active : .passive

        // One notification per place: a repeat replaces the earlier one instead of stacking.
        let request = UNNotificationRequest(
            identifier: "proximity.\(content.placeID)",
            content: notification,
            trigger: nil
        )
        try await center.add(request)
    }
}
