import MapKit
import Observation
import SwiftUI

@Observable
final class LocationMapViewModel {
    private let service: LocationMapServicing

    var cameraPosition: MapCameraPosition = .automatic
    var userCoordinate: UserCoordinate?
    var isLoading = false
    var errorMessage: String?

    init(service: LocationMapServicing = LocationMapService()) {
        self.service = service
    }

    func loadUserLocation() async {
        isLoading = true
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
            errorMessage = error.localizedDescription
        }
    }
}
