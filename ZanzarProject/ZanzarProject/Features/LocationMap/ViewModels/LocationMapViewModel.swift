import MapKit
import Observation
import SwiftUI

@Observable
final class LocationMapViewModel {
    private let store: NearbyPlacesStore
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

    /// The app passes the store it shares with the other tabs; without one (tests, previews) the view model
    /// builds its own on top of `service`.
    init(service: LocationMapServicing? = nil, store: NearbyPlacesStore? = nil) {
        self.store = store ?? NearbyPlacesStore(service: service ?? LocationMapService())
    }

    /// Centers the camera on the user and shows the places. Goes to the server only when the shared store
    /// has nothing fresh, so coming back to the screen does not cost a request.
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
            try await store.refreshIfNeeded()
            guard generation == loadGeneration else { return }

            centerCamera(on: store.userCoordinate)
            setPlaces(store.places)
        } catch let error as LocationMapError {
            guard generation == loadGeneration else { return }

            userCoordinate = nil
            setPlaces([])
            errorMessage = error.errorDescription ?? error.localizedDescription
        } catch {
            guard generation == loadGeneration else { return }

            // The position is known (the fetch is what failed), so the camera still goes to the user.
            centerCamera(on: store.userCoordinate)
            guard !Self.isCancellation(error) else { return }

            setPlaces(store.places)
            errorMessage = APIError.rateLimitedMessage(for: error) ?? String(localized: "locationMap.placesLoadError")
        }
    }

    /// Mirrors the shared store into the pins, e.g. after another screen refreshed it.
    func syncPlaces() {
        guard places != store.places else { return }
        setPlaces(store.places)
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

    /// Refreshes the pins after the map becomes visible again. Skipped while the data is fresh unless `force`.
    func reloadPlaces(force: Bool = false) async {
        guard acceptsVisibleRegionUpdates else { return }

        loadGeneration += 1
        let generation = loadGeneration

        do {
            if force {
                try await store.refresh()
            } else {
                try await store.refreshIfNeeded()
            }
            guard generation == loadGeneration else { return }
            setPlaces(store.places)
        } catch {
            guard generation == loadGeneration, !Self.isCancellation(error) else { return }
            errorMessage = APIError.rateLimitedMessage(for: error) ?? String(localized: "locationMap.placesLoadError")
        }
    }

    private func centerCamera(on coordinate: UserCoordinate?) {
        guard let coordinate else { return }
        userCoordinate = coordinate
        let region = MKCoordinateRegion(
            center: coordinate.clLocationCoordinate2D,
            latitudinalMeters: 1000,
            longitudinalMeters: 1000
        )
        setRegion(region)
        cameraPosition = .region(region)
    }

    /// URLSession reports a cancelled task as `URLError.cancelled`, which also bridges to
    /// `NSError` (`NSURLErrorDomain` / `NSURLErrorCancelled`), not `CancellationError`.
    /// Leaving the map cancels the in-flight places reload; that must not become a toast.
    private static func isCancellation(_ error: Error) -> Bool {
        if error is CancellationError { return true }
        if (error as? URLError)?.code == .cancelled { return true }
        let nsError = error as NSError
        return nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled
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
