import Foundation
import Testing
@testable import ZanzarProject

/// The notices under the map's search bar and the empty card (Figma D2 and D4).
@MainActor
@Suite("LocationMapViewModel notices")
struct LocationMapViewModelNoticeTests {
    private static let square = MapPlace(
        id: "p", name: "Praça", latitude: -25.43, longitude: -49.27, category: .park, distanceMeters: 10
    )

    @Test("a position that is not precise enough raises the notice, and a better one takes it away")
    func lowAccuracyNotice() async {
        let service = MockLocationMapService()
        service.locationResult = .success(UserCoordinate(latitude: -25.43, longitude: -49.27, accuracyMeters: 80))
        service.placesResult = .success([])
        let viewModel = LocationMapViewModel(service: service)

        await viewModel.load()

        #expect(viewModel.hasLowAccuracy)
        #expect(viewModel.noticeMessage == L10n.string("locationMap.lowAccuracy.message"))

        service.locationResult = .success(UserCoordinate(latitude: -25.43, longitude: -49.27, accuracyMeters: 15))
        await viewModel.load()

        #expect(!viewModel.hasLowAccuracy)
        #expect(viewModel.noticeMessage == nil)
    }

    @Test("an invalid accuracy counts as imprecise, an unknown one does not")
    func accuracyEdges() async {
        let service = MockLocationMapService()
        service.placesResult = .success([])
        let viewModel = LocationMapViewModel(service: service)

        service.locationResult = .success(UserCoordinate(latitude: -25.43, longitude: -49.27, accuracyMeters: -1))
        await viewModel.load()
        #expect(viewModel.hasLowAccuracy)

        service.locationResult = .success(UserCoordinate(latitude: -25.43, longitude: -49.27, accuracyMeters: 50))
        await viewModel.load()
        #expect(!viewModel.hasLowAccuracy)

        service.locationResult = .success(UserCoordinate(latitude: -25.43, longitude: -49.27))
        await viewModel.load()
        #expect(!viewModel.hasLowAccuracy)
    }

    @Test("a load problem wins over the accuracy notice")
    func loadErrorWinsOverAccuracy() async {
        let service = MockLocationMapService()
        service.locationResult = .success(UserCoordinate(latitude: -25.43, longitude: -49.27, accuracyMeters: 90))
        service.placesResult = .failure(URLError(.notConnectedToInternet))
        let viewModel = LocationMapViewModel(service: service)

        await viewModel.load()

        #expect(viewModel.noticeMessage == viewModel.errorMessage)
        #expect(viewModel.errorMessage != nil)
    }

    @Test("the empty card shows only when the places loaded and none is on the map")
    func emptyState() async {
        let service = MockLocationMapService()
        service.locationResult = .success(UserCoordinate(latitude: -25.43, longitude: -49.27))
        service.placesResult = .success([])
        let viewModel = LocationMapViewModel(service: service)
        #expect(!viewModel.showsEmptyState)

        await viewModel.load()
        #expect(viewModel.showsEmptyState)

        service.placesResult = .success([Self.square])
        await viewModel.reloadPlaces(force: true)
        #expect(!viewModel.showsEmptyState)

        viewModel.setFilter(PlaceFilter(categories: [.museum]))
        #expect(viewModel.showsEmptyState)
    }
}
