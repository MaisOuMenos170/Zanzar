import Foundation
import Testing
@testable import ZanzarProject

@MainActor
@Suite("Itinerary sheet seals and places")
struct ItineraryDetailSealsTests {
    private static func detail(
        routeType: ItineraryRouteType,
        places: [ItineraryDetailPlace] = [],
        targetCategory: ZanzarPlaceCategory? = nil,
        placesCount: Int? = nil
    ) -> ItineraryDetail {
        ItineraryDetail(
            slug: "roteiro",
            name: "Roteiro",
            description: "",
            category: "x",
            routeType: routeType,
            objectives: [],
            targetCategory: targetCategory,
            targetCount: routeType == .free ? placesCount : nil,
            placesCount: placesCount ?? places.count,
            completedCount: 0,
            coverImageURL: nil,
            places: places
        )
    }

    private static let paco = ItineraryDetailPlace(
        placeID: "paco", name: "Paço", latitude: -25.43, longitude: -49.27, category: .historic
    )
    private static let museu = ItineraryDetailPlace(
        placeID: "museu", name: "Museu", latitude: -25.44, longitude: -49.26, category: .museum
    )

    private static func active(
        _ slots: [(placeID: String?, done: Bool)],
        slug: String = "roteiro"
    ) -> ActiveItinerary {
        ActiveItinerary(
            templateID: "1", slug: slug, name: "Roteiro", description: "", category: "x",
            routeType: .fixed, objectives: [], targetCategory: nil, targetCount: nil, startedAt: .now,
            places: slots.enumerated().map { index, slot in
                ItinerarySlot(
                    id: "\(index)", placeID: slot.placeID, placeName: nil,
                    isCompleted: slot.done, completedAt: nil, stampID: nil
                )
            }
        )
    }

    private func loadedModel(detail: ItineraryDetail, active: ActiveItinerary?) async -> ItineraryDetailViewModel {
        let service = MockItineraryService(detailResult: .success(detail), activeItineraryResult: .success(active))
        let model = ItineraryDetailViewModel(slug: "roteiro", service: service, userIDProvider: { "user" })
        await model.load()
        return model
    }

    // MARK: - Seals

    @Test("a roteiro the user has not started shows empty seals")
    func notStarted() async {
        let model = await loadedModel(
            detail: Self.detail(routeType: .fixed, places: [Self.paco, Self.museu]),
            active: nil
        )

        #expect(model.sealSlots.map(\.isEarned) == [false, false])
        #expect(model.sealSlots.map(\.category) == [.historic, .museum])
        #expect(model.collectedCount == 0)
    }

    @Test("the roteiro in progress shows what the user has earned, with the seal of each place")
    func inProgress() async {
        let model = await loadedModel(
            detail: Self.detail(routeType: .fixed, places: [Self.paco, Self.museu]),
            active: Self.active([("paco", true), ("museu", false)])
        )

        #expect(model.sealSlots.map(\.isEarned) == [true, false])
        #expect(model.sealSlots.map(\.category) == [.historic, .museum])
        #expect(model.collectedCount == 1)
    }

    @Test("progress in another roteiro does not show on this one")
    func otherActiveItinerary() async {
        let model = await loadedModel(
            detail: Self.detail(routeType: .fixed, places: [Self.paco]),
            active: Self.active([("x", true)], slug: "outro")
        )

        #expect(model.collectedCount == 0)
        #expect(model.sealSlots.count == 1)
    }

    @Test("a free route's seals all use the category it asks for")
    func freeRouteSeals() async {
        let model = await loadedModel(
            detail: Self.detail(routeType: .free, targetCategory: .park, placesCount: 3),
            active: nil
        )

        #expect(model.sealSlots.count == 3)
        #expect(model.sealSlots.allSatisfy { $0.category == .park })
    }

    @Test("the seals match the places a fixed route asks for")
    func sealsMatchFixedPlaces() async {
        let places = (0..<5).map {
            ItineraryDetailPlace(placeID: "p\($0)", name: "P\($0)", latitude: 0, longitude: 0, category: .park)
        }
        let model = await loadedModel(detail: Self.detail(routeType: .fixed, places: places), active: nil)

        #expect(model.sealSlots.count == 5)
        #expect(model.detail?.requiredStops == 5)
    }

    @Test("the seals match the number of places a free route asks for")
    func sealsMatchFreeTarget() async {
        let model = await loadedModel(
            detail: Self.detail(routeType: .free, targetCategory: .park, placesCount: 5),
            active: nil
        )

        #expect(model.sealSlots.count == 5)
    }

    @Test("a roteiro in progress with fewer stops listed still shows every seal it asks for")
    func progressShorterThanRequired() async {
        let places = (0..<4).map {
            ItineraryDetailPlace(placeID: "p\($0)", name: "P\($0)", latitude: 0, longitude: 0, category: .park)
        }
        let model = await loadedModel(
            detail: Self.detail(routeType: .fixed, places: places),
            active: Self.active([("p0", true)])
        )

        #expect(model.sealSlots.count == 4)
        #expect(model.sealSlots.map(\.isEarned) == [true, false, false, false])
    }

    // MARK: - Places near the roteiro

    private static func mapPlace(
        _ id: String, _ category: ZanzarPlaceCategory, distance: Double?, visited: Bool = false
    ) -> MapPlace {
        MapPlace(
            id: id, name: id, latitude: -25.4, longitude: -49.2, category: category,
            distanceMeters: distance, pinStyle: visited ? .checkedIn : .available
        )
    }

    @Test("a fixed route suggests its own stops, the nearest not visited first")
    func fixedSuggestions() {
        let detail = Self.detail(routeType: .fixed, places: [Self.paco, Self.museu])
        let map = [
            Self.mapPlace("paco", .historic, distance: 900, visited: true),
            Self.mapPlace("museu", .museum, distance: 4000),
            Self.mapPlace("other", .park, distance: 10)
        ]

        #expect(detail.suggestedPlaces(from: map).map(\.id) == ["museu"])
    }

    @Test("when every stop was visited they are all suggested anyway")
    func everythingVisited() {
        let detail = Self.detail(routeType: .fixed, places: [Self.paco, Self.museu])
        let map = [
            Self.mapPlace("paco", .historic, distance: 900, visited: true),
            Self.mapPlace("museu", .museum, distance: 400, visited: true)
        ]

        #expect(detail.suggestedPlaces(from: map).map(\.id) == ["museu", "paco"])
    }

    @Test("a stop the map does not know is still suggested, from what the roteiro says about it")
    func unknownStop() {
        let detail = Self.detail(routeType: .fixed, places: [Self.paco])

        #expect(detail.suggestedPlaces(from: []).map(\.id) == ["paco"])
    }

    @Test("a free route suggests the nearest places of its category that were not visited")
    func freeSuggestions() {
        let detail = Self.detail(routeType: .free, targetCategory: .park, placesCount: 3)
        let map = [
            Self.mapPlace("far", .park, distance: 3000),
            Self.mapPlace("near", .park, distance: 200),
            Self.mapPlace("seen", .park, distance: 50, visited: true),
            Self.mapPlace("museum", .museum, distance: 10),
            Self.mapPlace("mid", .park, distance: 900)
        ]

        #expect(detail.suggestedPlaces(from: map).map(\.id) == ["near", "mid"])
        #expect(detail.suggestedPlaces(from: map, limit: 1).map(\.id) == ["near"])
    }

    // MARK: - Ver rota

    @Test("only a fixed route has stops to show on the map")
    func routeStops() {
        #expect(Self.detail(routeType: .fixed, places: [Self.paco]).routeStops.count == 1)
        #expect(Self.detail(routeType: .free, targetCategory: .park, placesCount: 3).routeStops.isEmpty)
    }

    @Test("the route link goes through every stop, on foot")
    func routeLink() throws {
        let url = try #require(ItineraryRouteLink.url(for: [Self.paco, Self.museu]))
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems

        #expect(url.host == "maps.apple.com")
        #expect(items?.first { $0.name == "daddr" }?.value == "-25.43,-49.27+to:-25.44,-49.26")
        #expect(items?.first { $0.name == "dirflg" }?.value == "w")
        #expect(ItineraryRouteLink.url(for: []) == nil)
    }
}
