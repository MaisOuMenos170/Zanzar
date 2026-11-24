import Foundation
import Testing
@testable import ZanzarProject

@Suite("ItineraryDetail place cards")
struct ItineraryDetailPlaceCardsTests {
    private static func detail(places: [ItineraryDetailPlace]) -> ItineraryDetail {
        ItineraryDetail(
            slug: "visitando-parques",
            name: "Visitando parques",
            description: "",
            category: "park",
            routeType: .free,
            objectives: [],
            targetCategory: .park,
            targetCount: 3,
            placesCount: places.count,
            completedCount: 0,
            coverImageURL: nil,
            places: places
        )
    }

    @Test("A place the map knows brings its check-ins; one it does not is built from the itinerary")
    func mapPlaceOrItineraryFallback() {
        let detail = Self.detail(places: [
            ItineraryDetailPlace(placeID: "known", name: "Itinerary name", latitude: 1, longitude: 2, category: .park),
            ItineraryDetailPlace(placeID: "unknown", name: "Bar do Zé", latitude: -25.4, longitude: -49.2, category: .bar)
        ])
        let mapPlaces = [
            MapPlace(
                id: "known",
                name: "Parque Barigui",
                latitude: -25.42,
                longitude: -49.31,
                category: .park,
                distanceMeters: 300,
                checkInCount: 21
            )
        ]

        let cards = detail.placeCards(from: mapPlaces)

        #expect(cards.map(\.id) == ["known", "unknown"])
        #expect(cards[0].name == "Parque Barigui")
        #expect(cards[0].checkInCount == 21)
        #expect(cards[1].name == "Bar do Zé")
        #expect(cards[1].category == .bar)
        #expect(cards[1].checkInCount == 0)
    }

    @Test("An itinerary without places has no cards")
    func noPlaces() {
        #expect(Self.detail(places: []).placeCards(from: []).isEmpty)
    }
}
