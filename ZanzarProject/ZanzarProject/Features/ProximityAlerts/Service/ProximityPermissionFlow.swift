import Foundation

/// The order in which the permissions are asked: notifications first, then "Always" location, one system dialog at
/// a time and only for what is still missing. Shared by the explanation card and the Profile settings.
struct ProximityPermissionFlow {
    nonisolated enum Outcome: Hashable, Sendable {
        case enabled
        /// The user refused notifications; only Settings can change that now.
        case notificationsRefused
        /// Location stayed below "Always", for instance "Keep Only While Using".
        case locationNotAlways
    }

    let service: ProximityPermissionServicing

    func run() async -> Outcome {
        var status = await service.status()

        if status.notifications == .notDetermined {
            await service.requestNotifications()
            status = await service.status()
        }
        guard status.notifications == .allowed else { return .notificationsRefused }

        if status.location != .always {
            await service.requestAlwaysLocation()
            status = await service.status()
        }
        return status.location == .always ? .enabled : .locationNotAlways
    }
}
