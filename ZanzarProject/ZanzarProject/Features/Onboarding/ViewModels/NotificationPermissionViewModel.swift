import Foundation
import Observation
import UIKit
import UserNotifications

/// Asks for notification permission during onboarding, using provisional authorization so alerts work
/// immediately without a system dialog. "Always" location is asked later, only when it has value
/// (first check-in or itinerary start), via the existing proximity-permission card.
@MainActor
@Observable
final class NotificationPermissionViewModel {
    enum Step: Equatable {
        case intro
        case working
        case enabled
        case refused
    }

    private(set) var step: Step = .intro
    private(set) var isWorking = false

    @ObservationIgnored private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    /// Called when the view appears. If notifications are already authorized (including provisionally),
    /// we are done. If not determined, we offer to turn them on.
    func checkStatus() async {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            step = .enabled
        case .notDetermined:
            step = .intro
        case .denied:
            step = .refused
        @unknown default:
            step = .refused
        }
    }

    /// Requests provisional authorization: notifications are posted quietly to Notification Center
    /// without a system prompt, and the user can later promote them to full alerts in Settings.
    func enableProvisional() async {
        isWorking = true
        defer { isWorking = false }

        do {
            try await center.requestAuthorization(options: [.provisional, .alert, .sound])
            step = .enabled
        } catch {
            step = .refused
        }
    }

    /// Declines notifications during onboarding. The user can still turn them on later from Settings.
    func skip() {
        step = .refused
    }

    func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
