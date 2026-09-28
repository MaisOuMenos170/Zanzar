import MapKit
import Observation
import SwiftUI

@Observable
final class LocationMapViewModel {
    private let service: LocationMapServicing

    var cameraPosition: MapCameraPosition = .automatic
    var userCoordinate: UserCoordinate?
    var places: [MapPlace] = []
    var isLoading = false
    var errorMessage: String?

    init(service: LocationMapServicing = LocationMapService()) {
        self.service = service
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let coordinate = try await service.currentUserLocation()
            userCoordinate = coordinate
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: coordinate.clLocationCoordinate2D,
                    latitudinalMeters: 1000,
                    longitudinalMeters: 1000
                )
            )
        } catch {
            userCoordinate = nil
            places = []
            errorMessage = error.localizedDescription
            return
        }

        guard let userCoordinate else { return }

        do {
            places = try await service.fetchNearbyPlaces(from: userCoordinate)
        } catch {
            places = []
            errorMessage = String(localized: "locationMap.placesLoadError")
        }
    }
}
