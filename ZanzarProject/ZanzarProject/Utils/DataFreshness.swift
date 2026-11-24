import CoreLocation
import Foundation

/// How long screen data is trusted before a screen asks the server again. Pull-to-refresh and the
/// "dirty" signals (a check-in, an itinerary change) always skip these limits.
nonisolated enum DataFreshness {
    /// Profile and itinerary tabs: re-entering the tab within this window shows what is already on screen.
    static let screenMaxAge: Duration = .seconds(90)
    /// Nearby places shared by the map, the itinerary tab and the place detail.
    static let placesMaxAge: Duration = .seconds(120)
    /// How far the user must walk, from where the places were fetched, before they are fetched again.
    static let minMovement: CLLocationDistance = 200
}
