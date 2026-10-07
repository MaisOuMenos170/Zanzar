import MapKit
import Observation
import SwiftUI

@Observable
final class LocationMapViewModel {
    private let service: LocationMapServicing
    private var loadGeneration = 0

    var cameraPosition: MapCameraPosition = .automatic
    var userCoordinate: UserCoordinate?
    private(set) var places: [MapPlace] = []
    private(set) var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    var isLoading = false
    var errorMessage: String?
    private(set) var acceptsVisibleRegionUpdates = false

    /// The pins to draw. Stored rather than computed so it is only rebuilt when the places or the zoom
    /// level change (never while merely panning), and it is only reassigned when the result differs, which
    /// keeps the annotations' identities, and so the map, steady.
    private(set) var displayItems: [MapPinDisplayItem] = []
    private var zoomLevel = MapPinClustering.zoomLevel(forSpan: 0.01, previous: nil)

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
            setRegion(region)
            cameraPosition = .region(region)
        } catch is CancellationError {
            return
        } catch {
            guard generation == loadGeneration else { return }

            userCoordinate = nil
            setPlaces([])
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            return
        }

        guard let userCoordinate else { return }

        do {
            let nearbyPlaces = try await service.fetchNearbyPlaces(from: userCoordinate)
            guard generation == loadGeneration else { return }
            setPlaces(nearbyPlaces)
        } catch is CancellationError {
            return
        } catch {
            guard generation == loadGeneration else { return }

            setPlaces([])
            errorMessage = String(localized: "locationMap.placesLoadError")
        }
    }

    func updateVisibleRegion(_ region: MKCoordinateRegion) {
        guard acceptsVisibleRegionUpdates else { return }
        setRegion(region)
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
        setRegion(region)
        cameraPosition = .region(region)
    }

    func reloadPlaces() async {
        guard acceptsVisibleRegionUpdates else { return }
        guard let userCoordinate else { return }

        loadGeneration += 1
        let generation = loadGeneration

        do {
            let refreshedPlaces = try await service.fetchNearbyPlaces(from: userCoordinate)
            guard generation == loadGeneration else { return }
            setPlaces(refreshedPlaces)
        } catch is CancellationError {
            return
        } catch {
            guard generation == loadGeneration else { return }
            errorMessage = String(localized: "locationMap.placesLoadError")
        }
    }

    // MARK: - Pin grouping

    private func setPlaces(_ newPlaces: [MapPlace]) {
        places = newPlaces
        refreshDisplayItems()
    }

    private func setRegion(_ region: MKCoordinateRegion) {
        mapRegion = region
        let span = max(region.span.latitudeDelta, region.span.longitudeDelta)
        let newLevel = MapPinClustering.zoomLevel(forSpan: span, previous: zoomLevel)
        guard newLevel != zoomLevel else { return }
        zoomLevel = newLevel
        refreshDisplayItems()
    }

    // Runs on the main actor (the project's default isolation) and only when the places or the zoom level
    // change, over a few dozen places, so there is nothing worth moving off the main thread. If the volume
    // ever grows to thousands, `MapPinClustering.cluster` is pure and Sendable and can become `@concurrent`
    // behind a generation check, like `loadGeneration`.
    private func refreshDisplayItems() {
        let items = MapPinClustering.cluster(places: places, zoomLevel: zoomLevel)
        if items != displayItems {
            displayItems = items
        }
    }
}
