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
    private(set) var acceptsVisibleRegionUpdates = false

    var displayItems: [MapPinDisplayItem] {
        MapPinClustering.cluster(places: places, region: mapRegion)
    }

    init(service: LocationMapServicing = LocationMapService()) {
        self.service = service
    }

    func load() async {
        loadGeneration += 1
        let generation = loadGeneration

        acceptsVisibleRegionUpdates = false
        isLoading = true
        errorMessage = nil
        defer {
            if generation == loadGeneration {
                isLoading = false
                acceptsVisibleRegionUpdates = true
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
        guard acceptsVisibleRegionUpdates else { return }
        mapRegion = region
    }

    func focusRegion(on cluster: MapPinCluster) -> MKCoordinateRegion {
        let latitudes = cluster.places.map(\.latitude)
        let longitudes = cluster.places.map(\.longitude)

        let minLatitude = latitudes.min() ?? cluster.latitude
        let maxLatitude = latitudes.max() ?? cluster.latitude
        let minLongitude = longitudes.min() ?? cluster.longitude
        let maxLongitude = longitudes.max() ?? cluster.longitude

        let latitudeDelta = max(
            (maxLatitude - minLatitude) * 1.6,
            MapPinClustering.zoomInSpanThreshold
        )
        let longitudeDelta = max(
            (maxLongitude - minLongitude) * 1.6,
            MapPinClustering.zoomInSpanThreshold
        )

        return MKCoordinateRegion(
            center: cluster.coordinate,
            span: MKCoordinateSpan(
                latitudeDelta: latitudeDelta,
                longitudeDelta: longitudeDelta
            )
        )
    }

    func applyCameraRegion(_ region: MKCoordinateRegion) {
        mapRegion = region
        cameraPosition = .region(region)
    }

    func reloadPlaces() async {
        guard let userCoordinate else { return }

        do {
            places = try await service.fetchNearbyPlaces(from: userCoordinate)
        } catch is CancellationError {
            return
        } catch {
            errorMessage = String(localized: "locationMap.placesLoadError")
        }
    }
}
