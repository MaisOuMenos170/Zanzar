import CoreLocation
import Foundation
import UIKit
import UserNotifications

/// The real permissions. Core Location does not call back when the user keeps "While Using" at the upgrade dialog,
/// so after asking it also waits for the app to come back to the foreground.
final class SystemProximityPermissionService: NSObject, ProximityPermissionServicing, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private let center: UNUserNotificationCenter
    private var authorizationChanged: CheckedContinuation<Void, Never>?

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
        super.init()
        manager.delegate = self
    }

    func status() async -> ProximityPermissionStatus {
        let notifications: ProximityPermissionStatus.Notifications
        switch await center.notificationSettings().authorizationStatus {
        case .authorized, .provisional, .ephemeral: notifications = .allowed
        case .denied: notifications = .denied
        case .notDetermined: notifications = .notDetermined
        @unknown default: notifications = .denied
        }
        return ProximityPermissionStatus(notifications: notifications, location: locationStatus)
    }

    func requestNotifications() async {
        _ = try? await center.requestAuthorization(options: [.alert, .sound])
    }

    func requestAlwaysLocation() async {
        if manager.authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
            await waitForAnswer()
        }
        if manager.authorizationStatus == .authorizedWhenInUse {
            manager.requestAlwaysAuthorization()
            await waitForAnswer()
        }
    }

    func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    // MARK: Location

    private var locationStatus: ProximityPermissionStatus.Location {
        switch manager.authorizationStatus {
        case .authorizedAlways: .always
        case .authorizedWhenInUse: .whenInUse
        case .denied, .restricted: .denied
        case .notDetermined: .notDetermined
        @unknown default: .denied
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        resumeWaiting()
    }

    private func resumeWaiting() {
        authorizationChanged?.resume()
        authorizationChanged = nil
    }

    /// Returns when the status changed, or when the system dialog was dismissed without changing it.
    private func waitForAnswer() async {
        let dialogDismissed = Task { [weak self] in
            let center = NotificationCenter.default
            for await _ in center.notifications(named: UIApplication.willResignActiveNotification) { break }
            for await _ in center.notifications(named: UIApplication.didBecomeActiveNotification) { break }
            self?.resumeWaiting()
        }
        let giveUp = Task { [weak self] in
            try? await Task.sleep(for: .seconds(60))
            self?.resumeWaiting()
        }
        await withCheckedContinuation { authorizationChanged = $0 }
        dialogDismissed.cancel()
        giveUp.cancel()
    }
}
