import MapKit
import SwiftUI
import Testing
@testable import ZanzarProject

@MainActor
@Suite("LocationMapViewModel")
struct LocationMapViewModelTests {
    @Test("Successful fetch updates the coordinate and camera, and clears loading")
    func successfulLoad() async throws {
        let coordinate = UserCoordinate(latitude: 37.7749, longitude: -122.4194)
        let service = MockLocationMapService()
        service.result = .success(coordinate)
        let viewModel = LocationMapViewModel(service: service)

        await viewModel.loadUserLocation()

        #expect(viewModel.userCoordinate == coordinate)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == nil)

        let region = try #require(viewModel.cameraPosition.region)
        #expect(region.center.latitude == coordinate.latitude)
        #expect(region.center.longitude == coordinate.longitude)
    }

    @Test("Failed fetch sets an error message and leaves the coordinate nil")
    func failedLoad() async {
        let service = MockLocationMapService()
        service.result = .failure(LocationMapError.authorizationDenied)
        let viewModel = LocationMapViewModel(service: service)

        await viewModel.loadUserLocation()

        #expect(viewModel.userCoordinate == nil)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage != nil)
    }
}

@MainActor
final class MockLocationMapService: LocationMapServicing {
    var result: Result<UserCoordinate, Error>?

    func currentUserLocation() async throws -> UserCoordinate {
        guard let result else {
            fatalError("MockLocationMapService.result not configured")
        }
        return try result.get()
    }
}
