import Foundation
import Testing
@testable import ZanzarProject

@Suite("ActiveItinerary place cards")
struct ActiveItineraryPlaceCardsTests {
    private static func itinerary(slots: [ItinerarySlot]) -> ActiveItinerary {
        ActiveItinerary(
            templateID: "template-1",
            slug: "centro-historico",
            name: "Centro Histórico",
            description: "",
            category: "history",
            routeType: .fixed,
            objectives: [],
            targetCategory: nil,
            targetCount: nil,
            startedAt: Date(timeIntervalSince1970: 0),
            places: slots
        )
    }

    private static func slot(_ placeID: String?) -> ItinerarySlot {
        ItinerarySlot(
            id: placeID ?? "slot-free",
            placeID: placeID,
            placeName: nil,
            isCompleted: false,
            completedAt: nil,
            stampID: nil
        )
    }

    private static func mapPlace(_ id: String, distance: Double) -> MapPlace {
        MapPlace(
            id: id,
            name: "Lugar \(id)",
            latitude: -25.43,
            longitude: -49.27,
            category: .park,
            distanceMeters: distance,
            checkInCount: 3
        )
    }

    @Test("Cards follow the route order, not the distance order of the map")
    func cardsFollowRouteOrder() {
        let itinerary = Self.itinerary(slots: [Self.slot("c"), Self.slot("a")])
        let mapPlaces = [
            Self.mapPlace("a", distance: 100),
            Self.mapPlace("b", distance: 200),
            Self.mapPlace("c", distance: 900)
        ]

        let cards = itinerary.placeCards(from: mapPlaces)

        #expect(cards.map(\.id) == ["c", "a"])
        #expect(cards.first?.checkInCount == 3)
    }

    @Test("Slots without a place and places the map does not know are left out")
    func skipsUnresolvedSlots() {
        let itinerary = Self.itinerary(slots: [Self.slot(nil), Self.slot("missing"), Self.slot("a")])

        let cards = itinerary.placeCards(from: [Self.mapPlace("a", distance: 100)])

        #expect(cards.map(\.id) == ["a"])
    }

    @Test("No cards when the map has no places yet")
    func noCardsWithoutMapPlaces() {
        let itinerary = Self.itinerary(slots: [Self.slot("a")])

        #expect(itinerary.placeCards(from: []).isEmpty)
    }
}
