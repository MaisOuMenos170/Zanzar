import CoreLocation
import MapKit

protocol PlaceGeocoding: Sendable {
    func address(for coordinate: CLLocationCoordinate2D) async throws -> String?
}

final class MapKitPlaceGeocoder: PlaceGeocoding {
    func address(for coordinate: CLLocationCoordinate2D) async throws -> String? {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        guard let request = MKReverseGeocodingRequest(location: location) else { return nil }
        let items = try await request.mapItems
        return items.first?.address?.fullAddress
    }
}
