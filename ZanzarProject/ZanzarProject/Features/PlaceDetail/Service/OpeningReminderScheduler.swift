import Foundation
import UserNotifications

/// "Avisar quando abrir": one local notification, at the minute the place opens, that opens the place when tapped.
@MainActor
protocol OpeningReminderScheduling {
    func isScheduled(placeID: String) async -> Bool
    /// Schedules the reminder. Returns `false`, scheduling nothing, when the user has not allowed notifications.
    func schedule(placeID: String, placeName: String, at date: Date) async throws -> Bool
    func cancel(placeID: String) async
    /// Drops every reminder, e.g. when the user signs out.
    func cancelAll() async
}

@MainActor
final class UserNotificationOpeningReminderScheduler: OpeningReminderScheduling {
    static let identifierPrefix = "opens."

    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func isScheduled(placeID: String) async -> Bool {
        await center.pendingNotificationRequests().contains { $0.identifier == Self.identifier(for: placeID) }
    }

    func schedule(placeID: String, placeName: String, at date: Date) async throws -> Bool {
        switch await center.notificationSettings().authorizationStatus {
        case .denied:
            return false
        case .notDetermined:
            // The user just asked for this reminder, so this is the moment to ask.
            guard try await center.requestAuthorization(options: [.alert, .sound]) else { return false }
        case .authorized, .provisional, .ephemeral:
            break
        @unknown default:
            return false
        }

        let content = UNMutableNotificationContent()
        content.title = placeName
        content.body = L10n.string("placeDetail.openingReminder.body", placeName)
        content.userInfo = ["placeID": placeID]
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, date.timeIntervalSinceNow), repeats: false)
        try await center.add(UNNotificationRequest(identifier: Self.identifier(for: placeID), content: content, trigger: trigger))
        return true
    }

    func cancel(placeID: String) async {
        center.removePendingNotificationRequests(withIdentifiers: [Self.identifier(for: placeID)])
    }

    func cancelAll() async {
        let ids = await center.pendingNotificationRequests().map(\.identifier).filter { $0.hasPrefix(Self.identifierPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    private static func identifier(for placeID: String) -> String { identifierPrefix + placeID }
}
