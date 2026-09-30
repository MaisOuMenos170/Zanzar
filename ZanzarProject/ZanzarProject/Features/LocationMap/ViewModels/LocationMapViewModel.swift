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
    var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    var isLoading = false
    var errorMessage: String?

    var displayItems: [MapPinDisplayItem] {
        MapPinClustering.cluster(places: places, region: mapRegion)
    }

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
            let region = MKCoordinateRegion(
                center: coordinate.clLocationCoordinate2D,
                latitudinalMeters: 1000,
                longitudinalMeters: 1000
            )
            mapRegion = region
            cameraPosition = .region(region)
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

    func updateVisibleRegion(_ region: MKCoordinateRegion) {
        mapRegion = region
    }

    func focus(on cluster: MapPinCluster) {
        let span = max(mapRegion.span.latitudeDelta, mapRegion.span.longitudeDelta)
        let zoomedSpan = span * 0.35

        let region = MKCoordinateRegion(
            center: cluster.coordinate,
            span: MKCoordinateSpan(
                latitudeDelta: zoomedSpan,
                longitudeDelta: zoomedSpan
            )
        )

        withAnimation(.smooth(duration: 0.45)) {
            mapRegion = region
            cameraPosition = .region(region)
        }
    }
}
