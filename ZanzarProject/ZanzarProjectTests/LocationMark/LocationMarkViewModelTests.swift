import Foundation
import Testing
@testable import ZanzarProject

@Suite("LocationMarkViewModel")
@MainActor
struct LocationMarkViewModelTests {
    @Test("Marks the user's location from the service")
    func marksCurrentLocation() async throws {
        let capturedAt = Date(timeIntervalSince1970: 1_700_000_000)
        let response = LocationMarkResponse(
            latitude: -23.5505,
            longitude: -46.6333,
            capturedAt: capturedAt,
            horizontalAccuracy: 8
        )
        let viewModel = LocationMarkViewModel(
            service: MockLocationMarkService(result: .success(response))
        )

        await viewModel.markCurrentLocation()

        let mark = try #require(viewModel.markedLocation)
        #expect(mark.latitude == -23.5505)
        #expect(mark.longitude == -46.6333)
        #expect(mark.capturedAt == capturedAt)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.isAuthorizationDenied == false)
        #expect(viewModel.isPresentingError == false)
    }

    @Test("Shows settings recovery when authorization is denied")
    func surfacesAuthorizationDenial() async {
        let viewModel = LocationMarkViewModel(
            service: MockLocationMarkService(result: .failure(LocationMarkError.authorizationDenied))
        )

        await viewModel.markCurrentLocation()

        #expect(viewModel.markedLocation == nil)
        #expect(viewModel.isAuthorizationDenied)
        #expect(viewModel.isPresentingError == false)
        #expect(viewModel.errorMessage == LocationMarkError.authorizationDenied.errorDescription)
        #expect(viewModel.isLoading == false)
    }

    @Test("Presents an alert when location is unavailable")
    func presentsAlertWhenLocationIsUnavailable() async {
        let viewModel = LocationMarkViewModel(
            service: MockLocationMarkService(result: .failure(LocationMarkError.unavailable))
        )

        await viewModel.markCurrentLocation()

        #expect(viewModel.markedLocation == nil)
        #expect(viewModel.isAuthorizationDenied == false)
        #expect(viewModel.isPresentingError)
        #expect(viewModel.errorMessage == LocationMarkError.unavailable.errorDescription)
    }
}

final class MockLocationMarkService: LocationMarkServicing {
    private let result: Result<LocationMarkResponse, Error>

    init(result: Result<LocationMarkResponse, Error>) {
        self.result = result
    }

    func currentLocation() async throws -> LocationMarkResponse {
        try result.get()
    }
}
