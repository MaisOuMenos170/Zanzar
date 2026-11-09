import CoreLocation
import Foundation

/// Picks the places worth watching. iOS lets an app monitor 20 regions, so the next stop of the roteiro goes first
/// and the nearest places to the user fill the rest. Places already checked in are never watched.
enum ProximityRegionSelector {
    /// Same as the check-in radius, so a notification always arrives while a check-in is possible.
    static let radius: CLLocationDistance = 150
    static let maxRegions = 20

    static func select(
        places: [MapPlace],
        user: UserCoordinate?,
        itinerary: ActiveItinerary?,
        limit: Int = maxRegions
    ) -> [ProximityPlaceSnapshot] {
        var selected: [ProximityPlaceSnapshot] = []
        var nextStopID: String?

        if let itinerary,
           let stopID = itinerary.nextPendingPlaceID,
           let stop = places.first(where: { $0.id == stopID }) {
            selected.append(ProximityPlaceSnapshot(place: stop, itineraryRunID: itinerary.runID))
            nextStopID = stopID
        }

        let others = places
            .filter { $0.pinStyle != .checkedIn && $0.id != nextStopID }
            .sorted { distance(to: $0, from: user) < distance(to: $1, from: user) }
            .prefix(max(limit - selected.count, 0))
            .map { ProximityPlaceSnapshot(place: $0, itineraryRunID: nil) }

        return Array((selected + others).prefix(limit))
    }

    private static func distance(to place: MapPlace, from user: UserCoordinate?) -> CLLocationDistance {
        guard let user else { return place.distanceMeters ?? .infinity }
        return CLLocation(latitude: user.latitude, longitude: user.longitude)
            .distance(from: CLLocation(latitude: place.latitude, longitude: place.longitude))
    }
}
