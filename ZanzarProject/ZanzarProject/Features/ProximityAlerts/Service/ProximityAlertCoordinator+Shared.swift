import Foundation
import UserNotifications

extension ProximityAlertCoordinator {
    /// One coordinator for the whole app: region events arrive from the system, not from a screen.
    static let shared = ProximityAlertCoordinator(
        monitor: CLMonitorProximityMonitor(),
        notifier: UserNotificationProximityNotifier(),
        store: UserDefaultsProximityAlertStore()
    )

    private static let notificationDelegate = ProximityNotificationDelegate()

    /// Call from the app's `init`, which also runs when iOS relaunches the app in the background for a region event.
    static func launch() {
        UNUserNotificationCenter.current().delegate = notificationDelegate
        shared.start()
    }
}
