import CoreLocation
import Foundation

nonisolated struct SuggestedLocation: Hashable, Sendable {
    let latitude: Double
    let longitude: Double
    let address: String

    var clLocationCoordinate2D: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    /// Used when reverse geocoding finds nothing, since the backend requires a non-empty `address`.
    static func coordinateText(latitude: Double, longitude: Double) -> String {
        String(format: "%.6f, %.6f", latitude, longitude)
    }
}
