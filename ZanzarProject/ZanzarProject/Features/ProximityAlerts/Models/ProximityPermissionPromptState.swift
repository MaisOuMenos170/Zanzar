import Foundation

/// How often the explanation has been shown, so it never turns into nagging.
nonisolated struct ProximityPermissionPromptState: Codable, Hashable, Sendable {
    var timesShown = 0
    var lastShownAt: Date?
}
