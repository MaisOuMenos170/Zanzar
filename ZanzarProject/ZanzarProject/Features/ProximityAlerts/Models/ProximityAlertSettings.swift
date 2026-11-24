import Foundation

/// What the user chose to be told about. Both are on until they say otherwise; the system permission
/// is a separate switch that is only asked for when it has value.
nonisolated struct ProximityAlertSettings: Codable, Hashable, Sendable {
    var nearbyPlacesEnabled = true
    var itineraryEnabled = true
}
