import Foundation
import Testing
@testable import ZanzarProject

@Suite("ProximityRegionSelector")
struct ProximityRegionSelectorTests {
    /// Places spread along a line east of the user: `p0` is the nearest.
    private func place(_ index: Int, style: LocationPinStyle = .available) -> MapPlace {
        MapPlace(
            id: "p\(index)",
            name: "Place \(index)",
            latitude: -25.4,
            longitude: -49.3 + Double(index) * 0.001,
            category: .bar,
            distanceMeters: Double(index) * 100,
            pinStyle: style
        )
    }

    private let user = UserCoordinate(latitude: -25.4, longitude: -49.3)

    private func itinerary(next placeID: String?) -> ActiveItinerary {
        ActiveItinerary(
            templateID: "tpl",
            slug: "centro",
            name: "Centro",
            description: "",
            category: "history",
            routeType: .fixed,
            objectives: [],
            targetCategory: nil,
            targetCount: nil,
            startedAt: Date(timeIntervalSince1970: 1_000),
            places: [ItinerarySlot(
                id: "1",
                placeID: placeID,
                placeName: placeID,
                isCompleted: false,
                completedAt: nil,
                stampID: nil
            )]
        )
    }

    @Test("Picks the nearest places first")
    func nearestFirst() {
        let places = [place(3), place(1), place(2)]

        let selected = ProximityRegionSelector.select(places: places, user: user, itinerary: nil)

        #expect(selected.map(\.placeID) == ["p1", "p2", "p3"])
        #expect(selected.allSatisfy { $0.itineraryRunID == nil })
    }

    @Test("Never watches more than the limit")
    func limit() {
        let places = (1...30).map { place($0) }

        let selected = ProximityRegionSelector.select(places: places, user: user, itinerary: nil)

        #expect(selected.count == ProximityRegionSelector.maxRegions)
        #expect(selected.first?.placeID == "p1")
    }

    @Test("The next roteiro stop is watched first, even when it is far away, and carries the run id")
    func nextStopFirst() {
        let places = (1...30).map { place($0) }
        let active = itinerary(next: "p28")

        let selected = ProximityRegionSelector.select(places: places, user: user, itinerary: active)

        #expect(selected.first?.placeID == "p28")
        #expect(selected.first?.itineraryRunID == active.runID)
        #expect(selected.count == ProximityRegionSelector.maxRegions)
        #expect(selected.dropFirst().map(\.placeID).first == "p1")
        #expect(Set(selected.map(\.placeID)).count == selected.count)
    }

    @Test("Places already checked in are not watched")
    func skipsCheckedIn() {
        let places = [place(1, style: .checkedIn), place(2)]

        let selected = ProximityRegionSelector.select(places: places, user: user, itinerary: nil)

        #expect(selected.map(\.placeID) == ["p2"])
        #expect(selected.first?.hasCheckedIn == false)
    }

    @Test("A next stop the map has not loaded cannot be watched, and the rest still are")
    func unknownNextStop() {
        let selected = ProximityRegionSelector.select(
            places: [place(1)],
            user: user,
            itinerary: itinerary(next: "not-loaded")
        )

        #expect(selected.map(\.placeID) == ["p1"])
    }

    @Test("Without the user position the distance from the last fetch is used")
    func withoutUser() {
        let selected = ProximityRegionSelector.select(places: [place(5), place(2)], user: nil, itinerary: nil)

        #expect(selected.map(\.placeID) == ["p2", "p5"])
    }

    @Test("The snapshot keeps what the alert needs after a relaunch")
    func snapshotContent() {
        let selected = ProximityRegionSelector.select(places: [place(1)], user: user, itinerary: nil)

        #expect(selected.first?.name == "Place 1")
        #expect(selected.first?.latitude == -25.4)
    }
}
