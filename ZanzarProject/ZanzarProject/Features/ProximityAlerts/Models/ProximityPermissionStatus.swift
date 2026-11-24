import Foundation

/// The two system permissions proximity alerts need: notifications to show them, and "Always" location so iOS
/// wakes the app when the user walks into a watched circle.
nonisolated struct ProximityPermissionStatus: Hashable, Sendable {
    nonisolated enum Notifications: Hashable, Sendable {
        case notDetermined
        case allowed
        case denied
    }

    nonisolated enum Location: Hashable, Sendable {
        case notDetermined
        case whenInUse
        case always
        case denied
    }

    var notifications: Notifications
    var location: Location

    /// Everything is granted; alerts can work with the app closed.
    var isComplete: Bool {
        notifications == .allowed && location == .always
    }

    /// The user said no at the system level. Asking again does nothing; only Settings can change it.
    var isBlocked: Bool {
        notifications == .denied || location == .denied
    }
}
