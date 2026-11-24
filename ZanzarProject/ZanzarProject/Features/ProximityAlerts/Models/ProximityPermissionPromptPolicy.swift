import Foundation

/// Decides whether it is time to explain proximity alerts again. A "Not now" is respected for weeks.
nonisolated struct ProximityPermissionPromptPolicy: Sendable {
    var maxTimesShown = 3
    var minimumSpacing: TimeInterval = 14 * 24 * 3_600

    func shouldShow(_ state: ProximityPermissionPromptState, now: Date) -> Bool {
        guard state.timesShown < maxTimesShown else { return false }
        guard let lastShownAt = state.lastShownAt else { return true }
        return now.timeIntervalSince(lastShownAt) >= minimumSpacing
    }
}
