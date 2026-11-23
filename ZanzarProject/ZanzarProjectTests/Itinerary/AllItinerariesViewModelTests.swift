import Foundation
import Testing
@testable import ZanzarProject

@MainActor
@Suite("AllItinerariesViewModel")
struct AllItinerariesViewModelTests {
    private static func itinerary(_ slug: String, _ name: String, themes: [ItineraryTheme]) -> Itinerary {
        Itinerary(
            slug: slug,
            name: name,
            category: "historic",
            routeType: .fixed,
            placesCount: 4,
            completedCount: 0,
            coverImageURL: nil,
            themes: themes
        )
    }

    private static let centro = itinerary("centro", "Bora passear no centro histórico?", themes: [.center, .walking])
    private static let parques = itinerary("parques", "Visitando parques", themes: [.parks])
    private static let untagged = itinerary("misterio", "Roteiro misterioso", themes: [])

    private func loadedModel(_ items: [Itinerary]) async -> AllItinerariesViewModel {
        let model = AllItinerariesViewModel(service: MockItineraryService(itinerariesResult: .success(items)))
        await model.load()
        return model
    }

    @Test("loads every roteiro and shows them all under Todos")
    func loadsAll() async {
        let model = await loadedModel([Self.centro, Self.parques, Self.untagged])

        #expect(model.hasLoaded)
        #expect(model.visibleItineraries.count == 3)
    }

    @Test("a theme chip keeps only the roteiros tagged with it")
    func filtersByTheme() async {
        let model = await loadedModel([Self.centro, Self.parques, Self.untagged])

        model.filter = .parks
        #expect(model.visibleItineraries == [Self.parques])

        model.filter = .walking
        #expect(model.visibleItineraries == [Self.centro])

        model.filter = .museums
        #expect(model.visibleItineraries.isEmpty)
    }

    @Test("search matches the name, ignoring case and accents")
    func searchesByName() async {
        let model = await loadedModel([Self.centro, Self.parques])

        model.searchText = "  HISTORICO "
        #expect(model.visibleItineraries == [Self.centro])

        model.searchText = "picolé"
        #expect(model.visibleItineraries.isEmpty)
    }

    @Test("search and theme combine")
    func searchAndThemeCombine() async {
        let model = await loadedModel([Self.centro, Self.parques])

        model.searchText = "parques"
        model.filter = .center
        #expect(model.visibleItineraries.isEmpty)
    }

    @Test("a failed load with nothing on screen shows a message and can be retried")
    func failedLoad() async {
        let service = MockItineraryService(itinerariesResult: .failure(APIError.invalidResponse))
        let model = AllItinerariesViewModel(service: service)
        await model.load()

        #expect(model.errorMessage != nil)
        #expect(!model.hasLoaded)

        service.itinerariesResult = .success([Self.parques])
        await model.load()
        #expect(model.errorMessage == nil)
        #expect(model.visibleItineraries == [Self.parques])
    }

    @Test("a failed refresh keeps the roteiros already shown")
    func failedRefreshKeepsList() async {
        let service = MockItineraryService(itinerariesResult: .success([Self.parques]))
        let model = AllItinerariesViewModel(service: service)
        await model.load()

        service.itinerariesResult = .failure(APIError.invalidResponse)
        await model.load()

        #expect(model.visibleItineraries == [Self.parques])
    }
}
