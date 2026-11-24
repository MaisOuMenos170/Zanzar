import Foundation

extension PlaceSuggestionService {
    /// The app's service: the position comes from the map's location service.
    convenience init(
        client: NetworkClient = URLSessionNetworkClient.shared,
        locationService: LocationMapServicing = LocationMapService.shared,
        geocoder: PlaceGeocoding = MapKitPlaceGeocoder()
    ) {
        self.init(
            client: client,
            userPosition: {
                let position = try await locationService.currentUserLocation()
                return (position.latitude, position.longitude)
            },
            geocoder: geocoder
        )
    }
}
