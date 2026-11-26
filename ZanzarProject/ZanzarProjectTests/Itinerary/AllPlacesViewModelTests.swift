import Foundation
import Testing
@testable import ZanzarProject

@MainActor
@Suite("AllPlacesViewModel")
struct AllPlacesViewModelTests {
    private static func place(
        _ id: String,
        _ name: String,
        category: ZanzarPlaceCategory,
        distance: Double?,
        nickname: String? = nil
    ) -> MapPlace {
        MapPlace(
            id: id,
            name: name,
            nickname: nickname,
            latitude: -25.43,
            longitude: -49.27,
            category: category,
            distanceMeters: distance
        )
    }

    private static let places = [
        place("far", "Museu Oscar Niemeyer", category: .museum, distance: 4200),
        place("near", "Praça Tiradentes", category: .historic, distance: 300),
        place("unknown", "Jardim Botânico", category: .park, distance: nil),
        place("mid", "Parque Barigui", category: .park, distance: 1500)
    ]

    @Test("lists the nearest first and the ones without a distance last")
    func sortsByDistance() {
        let model = AllPlacesViewModel()

        #expect(model.visiblePlaces(from: Self.places).map(\.id) == ["near", "mid", "far", "unknown"])
    }

    @Test("a category chip keeps only its places")
    func filtersByCategory() {
        let model = AllPlacesViewModel()

        model.filter = .parks
        #expect(model.visiblePlaces(from: Self.places).map(\.id) == ["mid", "unknown"])

        model.filter = .museums
        #expect(model.visiblePlaces(from: Self.places).map(\.id) == ["far"])
    }

    @Test("search matches the name ignoring case and accents")
    func searchesByName() {
        let model = AllPlacesViewModel()

        model.searchText = " botanico "
        #expect(model.visiblePlaces(from: Self.places).map(\.id) == ["unknown"])

        model.searchText = "Casa do Sapo"
        #expect(model.visiblePlaces(from: Self.places).isEmpty)
    }

    @Test("search also finds a place by its nickname")
    func searchesByNickname() {
        let places = [Self.place("1", "Passeio Público", category: .park, distance: 100, nickname: "Passeio")]
        let model = AllPlacesViewModel()

        model.searchText = "passeio público"
        #expect(model.visiblePlaces(from: places).map(\.id) == ["1"])
    }

    @Test("a failed load is an error to show, not an empty list, and a retry clears it")
    func failedLoadIsReported() async {
        let service = MockLocationMapService()
        service.locationResult = .success(UserCoordinate(latitude: -25.43, longitude: -49.27))
        service.placesResult = .failure(URLError(.notConnectedToInternet))
        let store = NearbyPlacesStore(service: service)
        let model = AllPlacesViewModel()

        await model.load(using: store)

        #expect(model.loadErrorMessage == L10n.string("locationMap.placesLoadError"))

        service.placesResult = .success([Self.places[0]])
        await model.load(using: store, force: true)

        #expect(model.loadErrorMessage == nil)
        #expect(store.places.count == 1)
    }

    @Test("a position that cannot be read says so")
    func missingLocationIsReported() async {
        let service = MockLocationMapService()
        service.locationResult = .failure(LocationMapError.authorizationDenied)
        let store = NearbyPlacesStore(service: service)
        let model = AllPlacesViewModel()

        await model.load(using: store)

        #expect(model.loadErrorMessage == LocationMapError.authorizationDenied.errorDescription)
    }
}

@Suite("ItineraryThemeFilter")
struct ItineraryThemeFilterTests {
    @Test("Todos includes every roteiro, tagged or not")
    func allIncludesEverything() {
        let untagged = Itinerary(
            slug: "a", name: "A", category: "x", routeType: .free,
            placesCount: 1, completedCount: 0, coverImageURL: nil
        )

        #expect(ItineraryThemeFilter.all.includes(untagged))
        #expect(!ItineraryThemeFilter.parks.includes(untagged))
    }

    @Test("each chip matches its own theme")
    func chipsMatchTheirTheme() {
        let food = Itinerary(
            slug: "b", name: "B", category: "x", routeType: .free,
            placesCount: 1, completedCount: 0, coverImageURL: nil, themes: [.food]
        )

        #expect(ItineraryThemeFilter.food.includes(food))
        #expect(!ItineraryThemeFilter.center.includes(food))
    }
}
