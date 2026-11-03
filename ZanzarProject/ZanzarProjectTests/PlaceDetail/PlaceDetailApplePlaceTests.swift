import CoreLocation
import MapKit
import Testing
@testable import ZanzarProject

@MainActor
@Suite("PlaceDetailViewModel Apple place")
struct PlaceDetailApplePlaceTests {
    private func makeViewModel(lookup: FakeApplePlaceLookup) -> PlaceDetailViewModel {
        PlaceDetailViewModel(
            place: PlaceDetailFixture.place,
            userIDProvider: { "user-1" },
            userCoordinateProvider: { PlaceDetailFixture.userCoordinate },
            service: MockPlaceDetailService(fetchResult: .success(PlaceDetailFixture.detail())),
            applePlaceLookup: lookup
        )
    }

    private static func mapItem() -> MKMapItem {
        MKMapItem(location: CLLocation(latitude: -25.4, longitude: -49.2), address: nil)
    }

    @Test("a found place is kept and not searched again")
    func foundPlaceIsKept() async {
        let item = Self.mapItem()
        let lookup = FakeApplePlaceLookup(results: [.success(item)])
        let viewModel = makeViewModel(lookup: lookup)

        await viewModel.loadApplePlace()
        await viewModel.loadApplePlace()

        #expect(viewModel.applePlaceItem === item)
        #expect(viewModel.applePlaceUnavailable == false)
        #expect(viewModel.isLookingUpApplePlace == false)
        #expect(lookup.requestedPlaceIDs == ["place-1"])
    }

    @Test("no match marks the place as unavailable")
    func noMatchMarksUnavailable() async {
        let lookup = FakeApplePlaceLookup(results: [.success(nil)])
        let viewModel = makeViewModel(lookup: lookup)

        await viewModel.loadApplePlace()
        await viewModel.loadApplePlace()

        #expect(viewModel.applePlaceItem == nil)
        #expect(viewModel.applePlaceUnavailable)
        #expect(lookup.requestedPlaceIDs.count == 1)
    }

    @Test("a failed search can be retried")
    func failureCanBeRetried() async {
        let item = Self.mapItem()
        let lookup = FakeApplePlaceLookup(results: [.failure(URLError(.notConnectedToInternet)), .success(item)])
        let viewModel = makeViewModel(lookup: lookup)

        await viewModel.loadApplePlace()
        #expect(viewModel.applePlaceItem == nil)
        #expect(viewModel.applePlaceUnavailable == false)

        await viewModel.loadApplePlace()
        #expect(viewModel.applePlaceItem === item)
    }
}

final class FakeApplePlaceLookup: ApplePlaceLookingUp {
    private var results: [Result<MKMapItem?, Error>]
    private(set) var requestedPlaceIDs: [String] = []

    init(results: [Result<MKMapItem?, Error>]) {
        self.results = results
    }

    func mapItem(for place: MapPlace) async throws -> MKMapItem? {
        requestedPlaceIDs.append(place.id)
        return try results.removeFirst().get()
    }
}
