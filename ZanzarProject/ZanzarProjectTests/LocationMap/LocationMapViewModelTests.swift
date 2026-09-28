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
            ),
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
