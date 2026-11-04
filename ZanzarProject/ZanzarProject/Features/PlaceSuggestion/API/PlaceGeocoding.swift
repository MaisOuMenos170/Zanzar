import CoreLocation
import MapKit

protocol PlaceGeocoding: Sendable {
    func address(for coordinate: CLLocationCoordinate2D) async throws -> String?

    func firstMatch(for query: String, near coordinate: CLLocationCoordinate2D?) async throws -> SuggestedLocation?
}

final class MapKitPlaceGeocoder: PlaceGeocoding {
    private static let searchSpanDegrees = 0.2

    func address(for coordinate: CLLocationCoordinate2D) async throws -> String? {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        guard let request = MKReverseGeocodingRequest(location: location) else { return nil }
        let items = try await request.mapItems
        return items.first?.address?.fullAddress
    }

    func firstMatch(for query: String, near coordinate: CLLocationCoordinate2D?) async throws -> SuggestedLocation? {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.resultTypes = [.address, .pointOfInterest]
        if let coordinate {
            request.region = MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(
                    latitudeDelta: Self.searchSpanDegrees,
                    longitudeDelta: Self.searchSpanDegrees
                )
            )
        }
        let response = try await MKLocalSearch(request: request).start()
        guard let item = response.mapItems.first else { return nil }
        let position = item.location.coordinate
        return SuggestedLocation(
            latitude: position.latitude,
            longitude: position.longitude,
            address: item.address?.fullAddress ?? query
        )
    }
}
