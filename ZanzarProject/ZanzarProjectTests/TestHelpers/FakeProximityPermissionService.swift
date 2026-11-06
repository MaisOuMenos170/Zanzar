import Foundation
@testable import ZanzarProject

/// A `ProximityPermissionServicing` whose answers tests decide. Each `request…` applies the answer the test chose
/// for it, like the user tapping a button on the system dialog.
final class FakeProximityPermissionService: ProximityPermissionServicing {
    var current: ProximityPermissionStatus
    /// What the notification dialog leaves behind.
    var notificationAnswer: ProximityPermissionStatus.Notifications = .allowed
    /// What the "Always" dialog leaves behind.
    var locationAnswer: ProximityPermissionStatus.Location = .always
    private(set) var notificationRequests = 0
    private(set) var locationRequests = 0
    private(set) var openedSettings = 0

    init(
        notifications: ProximityPermissionStatus.Notifications = .notDetermined,
        location: ProximityPermissionStatus.Location = .whenInUse
    ) {
        current = ProximityPermissionStatus(notifications: notifications, location: location)
    }

    func status() async -> ProximityPermissionStatus {
        current
    }

    func requestNotifications() async {
        notificationRequests += 1
        current.notifications = notificationAnswer
    }

    func requestAlwaysLocation() async {
        locationRequests += 1
        current.location = locationAnswer
    }

    func openSettings() {
        openedSettings += 1
    }
}
