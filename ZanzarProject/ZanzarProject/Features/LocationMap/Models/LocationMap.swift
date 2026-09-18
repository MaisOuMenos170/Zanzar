import CoreLocation

/// The user's current position on the map — the domain shape the View/ViewModel work with,
/// distinct from CoreLocation's `CLLocation` (which the Service layer deals with).
struct UserCoordinate: Hashable {
    let latitude: Double
    let longitude: Double

    var clLocationCoordinate2D: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
