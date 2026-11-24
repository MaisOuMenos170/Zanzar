import CoreLocation
import MapKit

protocol PlaceGeocoding: Sendable {
    func address(for coordinate: CLLocationCoordinate2D) async throws -> String?
    /// What Apple Maps finds for `query`, named places and addresses alike, closest to `near` first.
    /// With `includingPointsOfInterest` off only addresses come back, which is what an address typed by hand needs.
    func places(
        matching query: String,
        near: CLLocationCoordinate2D?,
        includingPointsOfInterest: Bool
    ) async throws -> [SuggestedPlace]
}

/// Curitiba and the cities around it, the only area the app covers.
nonisolated enum PlaceSearchArea {
    static let center = CLLocationCoordinate2D(latitude: -25.4284, longitude: -49.2733)
    static let latitudeRange = -25.70...(-25.25)
    static let longitudeRange = -49.50...(-49.05)
    /// How far Apple Maps looks around the center of the search.
    static let searchRadiusMeters: CLLocationDistance = 25_000

    static func contains(latitude: Double, longitude: Double) -> Bool {
        latitudeRange.contains(latitude) && longitudeRange.contains(longitude)
    }
}

/// Turns what Apple Maps knows about a result into a `SuggestedPlace`, deciding whether it has a name of its own.
nonisolated enum ApplePlaceResultMapper {
    /// - Parameters:
    ///   - name: Apple's name for the result. For an address it is the address itself ("Rua X, 350").
    ///   - hasCategory: Whether Apple classifies it as a point of interest (park, café, museum...).
    /// - Returns: `nil` when there is neither a name nor an address to show.
    static func place(
        name: String?,
        hasCategory: Bool,
        fullAddress: String?,
        shortAddress: String?,
        coordinate: CLLocationCoordinate2D
    ) -> SuggestedPlace? {
        var cleanName = clean(name)
        let cleanAddress = clean(fullAddress)

        // A result that is not a point of interest and is named after its own address (or its neighborhood)
        // is an address: nothing says what is there, so the user is asked.
        if let candidate = cleanName, !hasCategory,
           repeats(candidate, in: [clean(shortAddress), cleanAddress]) {
            cleanName = nil
        }

        guard cleanName != nil || cleanAddress != nil else { return nil }
        return SuggestedPlace(
            name: cleanName,
            address: cleanAddress,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
    }

    private static func clean(_ text: String?) -> String? {
        let trimmed = text?.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed?.isEmpty == false ? trimmed : nil
    }

    /// Whether `name` is just a piece of the address, ignoring case and accents.
    private static func repeats(_ name: String, in addresses: [String?]) -> Bool {
        let needle = fold(name)
        return addresses.contains { address in
            guard let address else { return false }
            return fold(address).contains(needle)
        }
    }

    private static func fold(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "pt_BR"))
    }
}

final class MapKitPlaceGeocoder: PlaceGeocoding {
    func address(for coordinate: CLLocationCoordinate2D) async throws -> String? {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        guard let request = MKReverseGeocodingRequest(location: location) else { return nil }
        let items = try await request.mapItems
        return items.first?.address?.fullAddress
    }

    func places(
        matching query: String,
        near: CLLocationCoordinate2D?,
        includingPointsOfInterest: Bool
    ) async throws -> [SuggestedPlace] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.resultTypes = includingPointsOfInterest ? [.pointOfInterest, .address] : [.address]
        let center = near.flatMap { coordinate in
            PlaceSearchArea.contains(latitude: coordinate.latitude, longitude: coordinate.longitude) ? coordinate : nil
        } ?? PlaceSearchArea.center
        request.region = MKCoordinateRegion(
            center: center,
            latitudinalMeters: PlaceSearchArea.searchRadiusMeters * 2,
            longitudinalMeters: PlaceSearchArea.searchRadiusMeters * 2
        )

        let items: [MKMapItem]
        do {
            items = try await MKLocalSearch(request: request).start().mapItems
        } catch let error as MKError where error.code == .placemarkNotFound {
            items = []
        }

        var seen = Set<String>()
        return items.compactMap { item -> SuggestedPlace? in
            let coordinate = item.location.coordinate
            guard PlaceSearchArea.contains(latitude: coordinate.latitude, longitude: coordinate.longitude),
                  let place = ApplePlaceResultMapper.place(
                      name: item.name,
                      hasCategory: item.pointOfInterestCategory != nil,
                      fullAddress: item.address?.fullAddress,
                      shortAddress: item.address?.shortAddress,
                      coordinate: coordinate
                  ),
                  seen.insert(place.id).inserted
            else { return nil }
            return place
        }
    }
}
