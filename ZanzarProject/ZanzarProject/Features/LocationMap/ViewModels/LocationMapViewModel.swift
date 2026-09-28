import MapKit
import Observation
import SwiftUI

@Observable
final class LocationMapViewModel {
    private let service: LocationMapServicing
    private var loadGeneration = 0

    var cameraPosition: MapCameraPosition = .automatic
    var userCoordinate: UserCoordinate?
    var places: [MapPlace] = []
    var isLoading = false
    var errorMessage: String?

    init(service: LocationMapServicing = LocationMapService()) {
        self.service = service
    }

    func load() async {
        loadGeneration += 1
        let generation = loadGeneration

        isLoading = true
        errorMessage = nil
        defer {
            if generation == loadGeneration {
                isLoading = false
            }
        }

        do {
            let coordinate = try await service.currentUserLocation()
            guard generation == loadGeneration else { return }

            userCoordinate = coordinate
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: coordinate.clLocationCoordinate2D,
                    latitudinalMeters: 1000,
                    longitudinalMeters: 1000
                )
            )
        } catch is CancellationError {
            return
        } catch {
            guard generation == loadGeneration else { return }

            userCoordinate = nil
            places = []
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            return
        }

        guard let userCoordinate else { return }

        do {
            places = try await service.fetchNearbyPlaces(from: userCoordinate)
            guard generation == loadGeneration else { return }
        } catch is CancellationError {
            return
        } catch {
            guard generation == loadGeneration else { return }

            places = []
            errorMessage = String(localized: "locationMap.placesLoadError")
        }
    }
}
