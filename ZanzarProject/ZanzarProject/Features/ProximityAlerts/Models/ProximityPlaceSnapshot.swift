import Foundation

/// Everything the alert needs to know about a monitored place, kept on disk. When iOS relaunches the app in the
/// background because the user came close to a place, the places fetched from the server are gone, so the
/// decision and the notification text are built from this copy.
nonisolated struct ProximityPlaceSnapshot: Codable, Hashable, Sendable {
    let placeID: String
    let name: String
    let latitude: Double
    let longitude: Double
    let openingHours: OpeningHours?
    let hasCheckedIn: Bool
    /// Set when this place is the next stop of the roteiro the user is following; `nil` for any other place.
    let itineraryRunID: String?
}

extension ProximityPlaceSnapshot {
    init(place: MapPlace, itineraryRunID: String?) {
        self.init(
            placeID: place.id,
            name: place.displayName,
            latitude: place.latitude,
            longitude: place.longitude,
            openingHours: place.openingHours,
            hasCheckedIn: place.pinStyle == .checkedIn,
            itineraryRunID: itineraryRunID
        )
    }
}
