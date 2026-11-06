import Foundation

/// What a sent alert was about. Unlike `ProximityAlertCandidate.Kind` it carries no roteiro run.
nonisolated enum ProximityAlertDeliveryKind: String, Codable, Hashable, Sendable {
    case nearbyPlace
    case itineraryStop
}
