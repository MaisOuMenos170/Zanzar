import MapKit
import SwiftUI
import Testing
@testable import ZanzarProject

@MainActor
@Suite("LocationMapViewModel")
struct LocationMapViewModelTests {
    @Test("Successful load updates coordinate, camera, and places")
    func successfulLoad() async throws {
        let coordinate = UserCoordinate(latitude: -25.4098994, longitude: -49.2670599)
        let places = [
            MapPlace(
                id: "ChIJFWlvqB_k3JQR7jsyAF9M8vU",
                name: "Museu Oscar Niemeyer | MON",
                latitude: -25.4098994,
                longitude: -49.2670599,
                category: .museum,
                distanceMeters: 0
            )
        ]
        let service = MockLocationMapService()
        service.locationResult = .success(coordinate)
        service.placesResult = .success(places)
        let viewModel = LocationMapViewModel(service: service)

        await viewModel.load()

        #expect(viewModel.userCoordinate == coordinate)
        #expect(viewModel.places == places)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == nil)

        let region = try #require(viewModel.cameraPosition.region)
        #expect(region.center.latitude == coordinate.latitude)
        #expect(region.center.longitude == coordinate.longitude)
    }

    @Test("Failed location fetch sets an error message and clears places")
    func failedLocationLoad() async {
        let service = MockLocationMapService()
        service.locationResult = .failure(LocationMapError.authorizationDenied)
        let viewModel = LocationMapViewModel(service: service)

        await viewModel.load()

        #expect(viewModel.userCoordinate == nil)
        #expect(viewModel.places.isEmpty)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == String(localized: "locationMap.locationAccessDenied"))
    }

    @Test("Cancelled load does not surface an error message")
    func cancelledLoad() async {
        let service = MockLocationMapService()
        service.locationResult = .success(UserCoordinate(latitude: -25.4098994, longitude: -49.2670599))
        service.placesResult = .failure(CancellationError())
        let viewModel = LocationMapViewModel(service: service)

        await viewModel.load()

        #expect(viewModel.errorMessage == nil)
    }

    @Test("Visible region updates are ignored until the initial load completes")
    func visibleRegionIgnoredDuringLoad() async {
        let viewModel = LocationMapViewModel(service: MockLocationMapService())
        let initialRegion = viewModel.mapRegion
        let updatedRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 1, longitude: 2),
            span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
        )

        viewModel.updateVisibleRegion(updatedRegion)

        #expect(viewModel.mapRegion.center.latitude == initialRegion.center.latitude)
        #expect(viewModel.mapRegion.center.longitude == initialRegion.center.longitude)
        #expect(viewModel.mapRegion.span.latitudeDelta == initialRegion.span.latitudeDelta)
        #expect(viewModel.mapRegion.span.longitudeDelta == initialRegion.span.longitudeDelta)
    }

    @Test("Visible region updates apply after the initial load completes")
    func visibleRegionUpdatesAfterLoad() async throws {
        let coordinate = UserCoordinate(latitude: -25.4098994, longitude: -49.2670599)
        let service = MockLocationMapService()
        service.locationResult = .success(coordinate)
        service.placesResult = .success([])
        let viewModel = LocationMapViewModel(service: service)

        await viewModel.load()

        let updatedRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: -25.5, longitude: -49.3),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
        viewModel.updateVisibleRegion(updatedRegion)

        #expect(viewModel.mapRegion.center.latitude == updatedRegion.center.latitude)
        #expect(viewModel.mapRegion.center.longitude == updatedRegion.center.longitude)
    }

    @Test("Display items cluster nearby places when the map is zoomed out")
    func displayItemsClusterWhenZoomedOut() async {
        let coordinate = UserCoordinate(latitude: -25.43, longitude: -49.27)
        let places = [
            MapPlace(
                id: "a",
                name: "A",
                latitude: -25.430,
                longitude: -49.270,
                category: .museum,
                distanceMeters: 0
            ),
            MapPlace(
                id: "b",
                name: "B",
                latitude: -25.4302,
                longitude: -49.2702,
                category: .museum,
                distanceMeters: 0
            )
        ]
        let service = MockLocationMapService()
        service.locationResult = .success(coordinate)
        service.placesResult = .success(places)
        let viewModel = LocationMapViewModel(service: service)

        await viewModel.load()
        viewModel.updateVisibleRegion(
            MKCoordinateRegion(
                center: coordinate.clLocationCoordinate2D,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        )

        #expect(viewModel.displayItems.count == 1)
        if case .cluster(let cluster) = viewModel.displayItems[0] {
            #expect(cluster.count == 2)
        } else {
            Issue.record("Expected a cluster display item")
        }
    }

    @Test("Panning at the same zoom does not rebuild the display items")
    func panningKeepsDisplayItems() async {
        let coordinate = UserCoordinate(latitude: -25.43, longitude: -49.27)
        let places = (0 ..< 12).map { index in
            MapPlace(
                id: "p\(index)",
                name: "P\(index)",
                latitude: -25.43 + Double(index) * 0.0011,
                longitude: -49.27 + Double(index % 3) * 0.0014,
                category: .museum,
                distanceMeters: 0
            )
        }
        let service = MockLocationMapService()
        service.locationResult = .success(coordinate)
        service.placesResult = .success(places)
        let viewModel = LocationMapViewModel(service: service)
        await viewModel.load()

        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        viewModel.updateVisibleRegion(MKCoordinateRegion(center: coordinate.clLocationCoordinate2D, span: span))
        let reference = viewModel.displayItems

        for step in 1 ... 20 {
            let center = CLLocationCoordinate2D(
                latitude: coordinate.latitude + Double(step) * 0.002,
                longitude: coordinate.longitude - Double(step) * 0.003
            )
            viewModel.updateVisibleRegion(MKCoordinateRegion(center: center, span: span))
            #expect(viewModel.displayItems == reference)
        }
    }

    @Test("Focus region zooms in below the individual pin threshold")
    func focusRegionExpandsClusterInOneStep() {
        let cluster = MapPinCluster(
            places: [
                MapPlace(
                    id: "a",
                    name: "A",
                    latitude: -25.430,
                    longitude: -49.270,
                    category: .museum,
                    distanceMeters: 0
                ),
                MapPlace(
                    id: "b",
                    name: "B",
                    latitude: -25.4302,
                    longitude: -49.2702,
                    category: .museum,
                    distanceMeters: 0
                )
            ],
            stableID: "cluster-test"
        )
        let viewModel = LocationMapViewModel()

        let region = viewModel.focusRegion(on: cluster)
        let span = max(region.span.latitudeDelta, region.span.longitudeDelta)

        #expect(span <= MapPinClustering.individualSpanThreshold)
    }

    @Test("reloadPlaces ignores stale responses when a newer load starts")
    func reloadPlacesIgnoresStaleResponses() async {
        let coordinate = UserCoordinate(latitude: -25.4098994, longitude: -49.2670599)
        let initialPlaces = [
            MapPlace(
                id: "initial",
                name: "Initial",
                latitude: -25.4098994,
                longitude: -49.2670599,
                category: .museum,
                distanceMeters: 0
            )
        ]
        let refreshedPlaces = [
            MapPlace(
                id: "refreshed",
                name: "Refreshed",
                latitude: -25.4098994,
                longitude: -49.2670599,
                category: .museum,
                distanceMeters: 0,
                pinStyle: .checkedIn
            )
        ]
        let service = MockLocationMapService()
        service.locationResult = .success(coordinate)
        service.placesResult = .success(initialPlaces)
        let viewModel = LocationMapViewModel(service: service)

        await viewModel.load()
        service.placesResult = .success(refreshedPlaces)
        await viewModel.reloadPlaces()

        #expect(viewModel.places == refreshedPlaces)
    }

    @Test("reloadPlaces does nothing before the initial load completes")
    func reloadPlacesWaitsForInitialLoad() async {
        let coordinate = UserCoordinate(latitude: -25.4098994, longitude: -49.2670599)
        let service = MockLocationMapService()
        service.locationResult = .success(coordinate)
        service.placesResult = .success([])
        let viewModel = LocationMapViewModel(service: service)

        await viewModel.reloadPlaces()

        #expect(viewModel.places.isEmpty)
    }

    @Test("Failed places fetch keeps the user coordinate and shows an error")
    func failedPlacesLoad() async {
        let coordinate = UserCoordinate(latitude: -25.4098994, longitude: -49.2670599)
        let service = MockLocationMapService()
        service.locationResult = .success(coordinate)
        service.placesResult = .failure(URLError(.badServerResponse))
        let viewModel = LocationMapViewModel(service: service)

        await viewModel.load()

        #expect(viewModel.userCoordinate == coordinate)
        #expect(viewModel.places.isEmpty)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == String(localized: "locationMap.placesLoadError"))
    }
}

@MainActor
final class MockLocationMapService: LocationMapServicing {
    var locationResult: Result<UserCoordinate, Error>?
    var placesResult: Result<[MapPlace], Error>?

    func currentUserLocation() async throws -> UserCoordinate {
        guard let locationResult else {
            fatalError("MockLocationMapService.locationResult not configured")
        }
        return try locationResult.get()
    }

    func fetchNearbyPlaces(from coordinate: UserCoordinate) async throws -> [MapPlace] {
        guard let placesResult else {
            fatalError("MockLocationMapService.placesResult not configured")
        }
        return try placesResult.get()
    }
}
