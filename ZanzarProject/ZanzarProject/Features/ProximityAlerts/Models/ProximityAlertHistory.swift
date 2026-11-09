import Foundation

/// What has already been sent, so the policy can keep the user from being nagged. Plain data: the policy
/// reads it and the caller records a delivery after it actually posts the notification.
nonisolated struct ProximityAlertHistory: Codable, Hashable, Sendable {
    nonisolated struct Delivery: Codable, Hashable, Sendable {
        let placeID: String
        let kind: ProximityAlertDeliveryKind
        let date: Date
    }

    var deliveries: [Delivery] = []
    /// `runID|placeID` of every roteiro stop already announced.
    var notifiedStopKeys: Set<String> = []

    static func stopKey(runID: String, placeID: String) -> String {
        "\(runID)|\(placeID)"
    }

    mutating func record(_ candidate: ProximityAlertCandidate, at date: Date) {
        switch candidate.kind {
        case .nearbyPlace:
            deliveries.append(Delivery(placeID: candidate.placeID, kind: .nearbyPlace, date: date))
        case .itineraryStop(let runID):
            deliveries.append(Delivery(placeID: candidate.placeID, kind: .itineraryStop, date: date))
            notifiedStopKeys.insert(Self.stopKey(runID: runID, placeID: candidate.placeID))
        }
    }

    /// Drops deliveries older than `retention` (nothing older can still block an alert) and the announced
    /// stops of every roteiro run except `activeRun`.
    func pruned(
        now: Date,
        keepingRun activeRun: String?,
        retention: TimeInterval = ProximityAlertPolicy.defaultPlaceCooldown
    ) -> ProximityAlertHistory {
        var copy = self
        copy.deliveries = deliveries.filter { now.timeIntervalSince($0.date) < retention }
        if let activeRun {
            copy.notifiedStopKeys = notifiedStopKeys.filter { $0.hasPrefix("\(activeRun)|") }
        } else {
            copy.notifiedStopKeys = []
        }
        return copy
    }
}
