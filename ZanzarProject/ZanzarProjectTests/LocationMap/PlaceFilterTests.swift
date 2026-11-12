import Testing
@testable import ZanzarProject

@Suite("PlaceFilter")
struct PlaceFilterTests {
    private func place(
        _ id: String,
        _ category: ZanzarPlaceCategory,
        pinStyle: LocationPinStyle = .available,
        isInActiveItinerary: Bool? = nil
    ) -> MapPlace {
        MapPlace(
            id: id,
            name: id,
            latitude: 0,
            longitude: 0,
            category: category,
            distanceMeters: 0,
            pinStyle: pinStyle,
            isInActiveItinerary: isInActiveItinerary
        )
    }

    @Test("An empty filter keeps everything")
    func emptyFilterKeepsEverything() {
        let places = [place("a", .bar), place("b", .cafe)]
        let filter = PlaceFilter()

        #expect(!filter.isActive)
        #expect(filter.activeCount == 0)
        #expect(filter.apply(to: places) == places)
    }

    @Test("Categories keep only the chosen types")
    func categoriesFilter() {
        let places = [place("a", .bar), place("b", .cafe), place("c", .park)]
        let filter = PlaceFilter(categories: [.bar, .park])

        #expect(filter.isActive)
        #expect(filter.activeCount == 2)
        #expect(filter.apply(to: places).map(\.id) == ["a", "c"])
    }

    @Test("\"No roteiro\" keeps the stops of the roteiro, visited or not")
    func itineraryFilter() {
        let places = [
            place("todo", .bar, pinStyle: .inCurrentItinerary),
            place("done", .bar, pinStyle: .checkedIn, isInActiveItinerary: true),
            place("other", .bar)
        ]
        let filter = PlaceFilter(onlyInItinerary: true)

        #expect(filter.apply(to: places).map(\.id) == ["todo", "done"])
    }

    @Test("Type and roteiro combine")
    func combinedFilter() {
        let places = [
            place("bar", .bar, pinStyle: .inCurrentItinerary),
            place("cafe", .cafe, pinStyle: .inCurrentItinerary),
            place("other bar", .bar)
        ]
        let filter = PlaceFilter(categories: [.bar], onlyInItinerary: true)

        #expect(filter.activeCount == 2)
        #expect(filter.apply(to: places).map(\.id) == ["bar"])
    }

    @Test("toggle adds and removes a category")
    func toggle() {
        var filter = PlaceFilter()

        filter.toggle(.museum)
        #expect(filter.categories == [.museum])

        filter.toggle(.museum)
        #expect(filter.categories.isEmpty)
    }

    @Test("The filter offers every real category and never the unknown one")
    func filterOptions() {
        let options = ZanzarPlaceCategory.filterOptions

        #expect(!options.contains(.unknown))
        #expect(options.count == ZanzarPlaceCategory.allCases.count - 1)
        #expect(Set(options.map(\.titleKey)).count == options.count)
    }
}
