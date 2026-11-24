import Foundation

/// Decides whether a place the user came close to deserves a notification. Pure: it reads the settings, the
/// history and the clock it is given, and never sends anything.
///
/// The limits are rolling windows, not calendar days, and there are no fixed quiet hours: someone out at
/// 2am next to a bar that is open should hear about it. The iOS Focus modes silence the rest.
nonisolated struct ProximityAlertPolicy: Sendable {
    nonisolated enum Decision: Hashable, Sendable {
        case send
        case skip(SkipReason)
    }

    nonisolated enum SkipReason: Hashable, Sendable {
        case disabled
        case alreadyCheckedIn
        case closed
        case dailyLimitReached
        case cooldown
        case stopAlreadyAnnounced
    }

    static let defaultPlaceCooldown: TimeInterval = 3 * 24 * 3_600

    /// Most nearby-place alerts inside `window`.
    var maxNearbyPerWindow = 2
    var window: TimeInterval = 24 * 3_600
    /// How long a place stays quiet after any alert about it.
    var placeCooldown: TimeInterval = defaultPlaceCooldown
    var timeZone = OpeningHours.defaultTimeZone

    func decide(
        _ candidate: ProximityAlertCandidate,
        settings: ProximityAlertSettings,
        history: ProximityAlertHistory,
        now: Date
    ) -> Decision {
        guard isEnabled(candidate.kind, in: settings) else { return .skip(.disabled) }
        guard !candidate.hasCheckedIn else { return .skip(.alreadyCheckedIn) }

        switch candidate.kind {
        case .itineraryStop(let runID):
            let key = ProximityAlertHistory.stopKey(runID: runID, placeID: candidate.placeID)
            if history.notifiedStopKeys.contains(key) { return .skip(.stopAlreadyAnnounced) }
        case .nearbyPlace:
            if let reason = nearbyLimitReason(for: candidate, history: history, now: now) { return .skip(reason) }
        }

        if let hours = candidate.openingHours, !hours.isOpen(at: now, in: timeZone) {
            return .skip(.closed)
        }
        return .send
    }

    private func isEnabled(_ kind: ProximityAlertCandidate.Kind, in settings: ProximityAlertSettings) -> Bool {
        switch kind {
        case .nearbyPlace: settings.nearbyPlacesEnabled
        case .itineraryStop: settings.itineraryEnabled
        }
    }

    private func nearbyLimitReason(
        for candidate: ProximityAlertCandidate,
        history: ProximityAlertHistory,
        now: Date
    ) -> SkipReason? {
        // A roteiro alert about the place counts too: the user has just been told about it.
        let inCooldown = history.deliveries.contains {
            $0.placeID == candidate.placeID && now.timeIntervalSince($0.date) < placeCooldown
        }
        if inCooldown { return .cooldown }

        let nearbyInWindow = history.deliveries.filter {
            $0.kind == .nearbyPlace && now.timeIntervalSince($0.date) < window
        }
        return nearbyInWindow.count >= maxNearbyPerWindow ? .dailyLimitReached : nil
    }
}
