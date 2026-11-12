import Testing
@testable import ZanzarProject

@MainActor
@Suite("LocationMapViewModel filter")
struct LocationMapViewModelFilterTests {
    private func place(
        _ id: String,
        _ category: ZanzarPlaceCategory,
        longitude: Double,
        inRoteiro: Bool = false
    ) -> MapPlace {
        MapPlace(
            id: id,
            name: id,
            latitude: -25.43,
            longitude: longitude,
            category: category,
            distanceMeters: 0,
            pinStyle: inRoteiro ? .inCurrentItinerary : .available
        )
    }

    private func loadedViewModel(places: [MapPlace]) async -> LocationMapViewModel {
        let service = MockLocationMapService()
        service.locationResult = .success(UserCoordinate(latitude: -25.43, longitude: -49.27))
        service.placesResult = .success(places)
        let viewModel = LocationMapViewModel(service: service)
        await viewModel.load()
        return viewModel
    }

    private func shownPlaceIDs(_ viewModel: LocationMapViewModel) -> [String] {
        viewModel.displayItems.flatMap { item -> [String] in
            switch item {
            case .place(let place):
                [place.id]
            case .cluster(let cluster):
                cluster.places.map(\.id)
            }
        }
        .sorted()
    }

    @Test("Only the places that pass the filter become pins")
    func filtersPins() async {
        let viewModel = await loadedViewModel(places: [
            place("bar", .bar, longitude: -49.27),
            place("cafe", .cafe, longitude: -49.20),
            place("park", .park, longitude: -49.30, inRoteiro: true)
        ])
        #expect(shownPlaceIDs(viewModel) == ["bar", "cafe", "park"])

        viewModel.setFilter(PlaceFilter(categories: [.bar]))
        #expect(shownPlaceIDs(viewModel) == ["bar"])

        viewModel.setFilter(PlaceFilter(onlyInItinerary: true))
        #expect(shownPlaceIDs(viewModel) == ["park"])

        viewModel.setFilter(PlaceFilter())
        #expect(shownPlaceIDs(viewModel) == ["bar", "cafe", "park"])
    }

    @Test("The filter does not drop the loaded places, only the pins")
    func keepsPlaces() async {
        let viewModel = await loadedViewModel(places: [
            place("bar", .bar, longitude: -49.27),
            place("cafe", .cafe, longitude: -49.20)
        ])

        viewModel.setFilter(PlaceFilter(categories: [.bar]))

        #expect(viewModel.places.count == 2)
        #expect(viewModel.filter == PlaceFilter(categories: [.bar]))
    }

    @Test("The filter applies to places that arrive later")
    func appliesToNewPlaces() async {
        let service = MockLocationMapService()
        service.locationResult = .success(UserCoordinate(latitude: -25.43, longitude: -49.27))
        service.placesResult = .success([place("bar", .bar, longitude: -49.27)])
        let viewModel = LocationMapViewModel(service: service)
        viewModel.setFilter(PlaceFilter(categories: [.cafe]))

        await viewModel.load()

        #expect(shownPlaceIDs(viewModel).isEmpty)
    }
}
