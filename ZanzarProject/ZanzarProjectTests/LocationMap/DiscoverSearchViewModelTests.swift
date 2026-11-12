import Foundation
import Testing
@testable import ZanzarProject

@MainActor
@Suite("DiscoverSearchViewModel")
struct DiscoverSearchViewModelTests {
    private static let home = UserCoordinate(latitude: -25.43, longitude: -49.27)

    private func place(_ id: String, _ category: ZanzarPlaceCategory = .cafe, inRoteiro: Bool = false) -> MapPlace {
        MapPlace(
            id: id,
            name: id,
            latitude: 0,
            longitude: 0,
            category: category,
            distanceMeters: 0,
            pinStyle: inRoteiro ? .inCurrentItinerary : .available
        )
    }

    private func makeViewModel(
        service: FakePlaceSearchService = FakePlaceSearchService(),
        coordinate: UserCoordinate? = home
    ) -> DiscoverSearchViewModel {
        DiscoverSearchViewModel(service: service, coordinateProvider: { coordinate }, debounce: .zero)
    }

    @Test("Fewer than two characters never reach the backend")
    func minimumLength() async {
        let service = FakePlaceSearchService()
        let viewModel = makeViewModel(service: service)

        viewModel.query = " a "
        await viewModel.waitForSearch()

        #expect(!viewModel.canSearch)
        #expect(viewModel.phase == .idle)
        #expect(service.requests.isEmpty)
    }

    @Test("A search sends the text, the position and the chosen types")
    func sendsRequest() async {
        let service = FakePlaceSearchService()
        service.result = .success([place("a"), place("b")])
        let viewModel = makeViewModel(service: service)
        viewModel.filter = PlaceFilter(categories: [.cafe, .bar])

        viewModel.query = "  caf "
        await viewModel.waitForSearch()

        #expect(service.requests == [.init(query: "caf", near: Self.home, categories: [.cafe, .bar])])
        #expect(viewModel.phase == .results)
        #expect(viewModel.results.map(\.id) == ["a", "b"])
        #expect(viewModel.showsResultsPanel)
    }

    @Test("Results keep the order the backend gave, nearest first")
    func keepsBackendOrder() async {
        let service = FakePlaceSearchService()
        service.result = .success([place("near"), place("middle"), place("far")])
        let viewModel = makeViewModel(service: service)

        viewModel.query = "ca"
        await viewModel.waitForSearch()

        #expect(viewModel.results.map(\.id) == ["near", "middle", "far"])
    }

    @Test("Typing again replaces the search that was still waiting")
    func latestSearchWins() async {
        let service = FakePlaceSearchService()
        service.result = .success([place("a")])
        let viewModel = DiscoverSearchViewModel(
            service: service,
            coordinateProvider: { Self.home },
            debounce: .milliseconds(200)
        )

        viewModel.query = "ca"
        viewModel.query = "caf"
        await viewModel.waitForSearch()

        #expect(service.requests.map(\.query) == ["caf"])
    }

    @Test("Changing the filter searches again without waiting")
    func filterTriggersSearch() async {
        let service = FakePlaceSearchService()
        let viewModel = makeViewModel(service: service)
        viewModel.query = "caf"
        await viewModel.waitForSearch()

        viewModel.filter.toggle(.bar)
        await viewModel.waitForSearch()

        #expect(service.requests.count == 2)
        #expect(service.requests.last?.categories == [.bar])
    }

    @Test("\"No roteiro\" drops the results that are not stops of the roteiro")
    func itineraryFilterOnResults() async {
        let service = FakePlaceSearchService()
        service.result = .success([place("a", inRoteiro: true), place("b")])
        let viewModel = makeViewModel(service: service)
        viewModel.filter = PlaceFilter(onlyInItinerary: true)

        viewModel.query = "ca"
        await viewModel.waitForSearch()

        #expect(viewModel.results.map(\.id) == ["a"])
        // The backend does not know about the roteiro, so it is not asked to filter by it.
        #expect(service.requests.last?.categories == [])
    }

    @Test("A failed search shows the error and no stale results")
    func failure() async {
        let service = FakePlaceSearchService()
        service.result = .success([place("a")])
        let viewModel = makeViewModel(service: service)
        viewModel.query = "ca"
        await viewModel.waitForSearch()

        service.result = .failure(URLError(.notConnectedToInternet))
        viewModel.query = "caf"
        await viewModel.waitForSearch()

        #expect(viewModel.phase == .failed)
        #expect(viewModel.results.isEmpty)
    }

    @Test("A cancelled request is not an error")
    func cancellationIsSilent() async {
        let service = FakePlaceSearchService()
        service.result = .failure(URLError(.cancelled))
        let viewModel = makeViewModel(service: service)

        viewModel.query = "caf"
        await viewModel.waitForSearch()

        #expect(viewModel.phase == .searching)
    }

    @Test("Without a position the search fails instead of asking the backend")
    func noPosition() async {
        let service = FakePlaceSearchService()
        let viewModel = makeViewModel(service: service, coordinate: nil)

        viewModel.query = "caf"
        await viewModel.waitForSearch()

        #expect(viewModel.phase == .failed)
        #expect(service.requests.isEmpty)
    }

    @Test("Clearing the text empties the results")
    func clearing() async {
        let service = FakePlaceSearchService()
        service.result = .success([place("a")])
        let viewModel = makeViewModel(service: service)
        viewModel.query = "caf"
        await viewModel.waitForSearch()

        viewModel.query = ""

        #expect(viewModel.results.isEmpty)
        #expect(viewModel.phase == .idle)
        #expect(!viewModel.showsResultsPanel)
    }

    @Test("reset clears the text and the results")
    func reset() async {
        let service = FakePlaceSearchService()
        service.result = .success([place("a")])
        let viewModel = makeViewModel(service: service)
        viewModel.query = "caf"
        await viewModel.waitForSearch()

        viewModel.reset()

        #expect(viewModel.query.isEmpty)
        #expect(viewModel.results.isEmpty)
        #expect(viewModel.phase == .idle)
    }
}

final class FakePlaceSearchService: PlaceSearchServicing, @unchecked Sendable {
    struct Request: Equatable {
        let query: String
        let near: UserCoordinate
        let categories: Set<ZanzarPlaceCategory>
    }

    var result: Result<[MapPlace], Error> = .success([])
    private(set) var requests: [Request] = []

    func searchPlaces(
        query: String,
        near coordinate: UserCoordinate,
        categories: Set<ZanzarPlaceCategory>
    ) async throws -> [MapPlace] {
        requests.append(Request(query: query, near: coordinate, categories: categories))
        return try result.get()
    }
}
