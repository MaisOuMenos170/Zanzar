import Foundation
import Testing
@testable import ZanzarProject

@MainActor
@Suite("LocationMapViewModel freshness and rate limit")
struct LocationMapViewModelFreshnessTests {
    @Test("reloadPlaces keeps the pins and skips the server while the places are fresh")
    func reloadPlacesSkipsFreshData() async {
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
        let service = MockLocationMapService()
        service.locationResult = .success(coordinate)
        service.placesResult = .success(initialPlaces)
        let viewModel = LocationMapViewModel(service: service)
        await viewModel.load()

        service.placesResult = .success([])
        await viewModel.reloadPlaces()

        #expect(viewModel.places == initialPlaces)
        #expect(service.fetchCount == 1)
    }

    @Test("A rate limited places fetch shows the rate limit message")
    func rateLimitedPlacesLoad() async {
        let service = MockLocationMapService()
        service.locationResult = .success(UserCoordinate(latitude: -25.4098994, longitude: -49.2670599))
        service.placesResult = .failure(APIError.rateLimited(retryAfter: 120))
        let viewModel = LocationMapViewModel(service: service)

        await viewModel.load()

        #expect(viewModel.errorMessage == APIError.rateLimited(retryAfter: 120).errorDescription)
        #expect(viewModel.errorMessage != L10n.string("locationMap.placesLoadError"))
    }
}
