import Foundation
import Observation

/// Drives the card that explains proximity alerts and asks for the permissions behind them.
///
/// It is shown at a moment the app is already useful to the user (a check-in, a roteiro just started), never at
/// launch, and only while something can still be granted. System dialogs only appear after the user taps "Turn on".
@Observable
final class ProximityPermissionViewModel {
    nonisolated enum Step: Hashable, Sendable {
        case intro
        case working
        case enabled
        /// A permission was refused at the system level: only Settings can fix it now.
        case needsSettings(Missing)
    }

    nonisolated enum Missing: Hashable, Sendable {
        case notifications
        case location
    }

    /// What led to the card; kept for the logs, it does not change the behaviour.
    nonisolated enum Moment: String, Sendable {
        case firstCheckIn
        case itineraryStarted
    }

    private(set) var isVisible = false
    private(set) var step: Step = .intro

    private let service: ProximityPermissionServicing
    private let store: ProximityAlertStoring
    private let policy: ProximityPermissionPromptPolicy
    private let now: () -> Date
    private let onPermissionsChanged: () async -> Void

    init(
        service: ProximityPermissionServicing,
        store: ProximityAlertStoring,
        policy: ProximityPermissionPromptPolicy = ProximityPermissionPromptPolicy(),
        now: @escaping () -> Date = { Date() },
        onPermissionsChanged: @escaping () async -> Void = {}
    ) {
        self.service = service
        self.store = store
        self.policy = policy
        self.now = now
        self.onPermissionsChanged = onPermissionsChanged
    }

    /// A good moment came up: shows the card if there is anything left to grant, the user did not refuse at the
    /// system level and it has not been shown too often.
    func momentOccurred(_ moment: Moment) async {
        guard !isVisible else { return }
        let status = await service.status()
        guard !status.isComplete, !status.isBlocked else { return }

        var state = store.loadPromptState()
        let currentTime = now()
        guard policy.shouldShow(state, now: currentTime) else { return }

        state.timesShown += 1
        state.lastShownAt = currentTime
        store.savePromptState(state)

        step = .intro
        isVisible = true
        AppLog.proximity.info("Showing the proximity permission card (\(moment.rawValue))")
    }

    /// "Turn on": asks for notifications, then for "Always" location, one system dialog at a time.
    func enable() async {
        step = .working
        switch await ProximityPermissionFlow(service: service).run() {
        case .enabled: step = .enabled
        case .notificationsRefused: step = .needsSettings(.notifications)
        case .locationNotAlways: step = .needsSettings(.location)
        }
        await onPermissionsChanged()
    }

    func dismiss() {
        isVisible = false
    }

    func openSettings() {
        service.openSettings()
        dismiss()
    }
}
