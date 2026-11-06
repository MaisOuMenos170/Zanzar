import Foundation
import Testing
@testable import ZanzarProject

@Suite("ProximityAlertRouter")
struct ProximityAlertRouterTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    private func mapPlace(_ id: String, name: String = "Loaded") -> MapPlace {
        MapPlace(id: id, name: name, latitude: -25.4, longitude: -49.3, category: .bar, distanceMeters: 10)
    }

    private func snapshot(_ id: String) -> ProximityPlaceSnapshot {
        ProximityPlaceSnapshot(
            placeID: id,
            name: "Saved",
            latitude: -25.5,
            longitude: -49.4,
            openingHours: nil,
            hasCheckedIn: false,
            itineraryRunID: nil
        )
    }

    // MARK: Pending tap

    @Test("A tap is kept until the screen takes it, once")
    func consumeOnce() {
        let router = ProximityAlertRouter()

        router.open(placeID: "bar", now: now)

        #expect(router.pendingPlaceID == "bar")
        #expect(router.consume(now: now.addingTimeInterval(5)) == "bar")
        #expect(router.pendingPlaceID == nil)
        #expect(router.consume(now: now.addingTimeInterval(6)) == nil)
    }

    @Test("A tap nobody picked up for a couple of minutes is forgotten, so it cannot open later by surprise")
    func expires() {
        let router = ProximityAlertRouter()
        router.open(placeID: "bar", now: now)

        #expect(router.consume(now: now.addingTimeInterval(121)) == nil)
        #expect(router.pendingPlaceID == nil)
    }

    @Test("A newer tap replaces an older one")
    func newerWins() {
        let router = ProximityAlertRouter()
        router.open(placeID: "first", now: now)
        router.open(placeID: "second", now: now.addingTimeInterval(1))

        #expect(router.consume(now: now.addingTimeInterval(2)) == "second")
    }

    // MARK: Notification payload

    @Test("Reads the place id from the notification")
    func parsesPayload() {
        #expect(ProximityAlertRouter.placeID(from: ["placeID": "bar"]) == "bar")
        #expect(ProximityAlertRouter.placeID(from: [:]) == nil)
        #expect(ProximityAlertRouter.placeID(from: ["placeID": 42]) == nil)
        #expect(ProximityAlertRouter.placeID(from: ["placeID": ""]) == nil)
    }

    // MARK: Resolving the place

    @Test("A place the map already loaded is preferred")
    func prefersLoaded() {
        let place = ProximityAlertRouter.place(
            for: "bar",
            loaded: [mapPlace("bar")],
            saved: [snapshot("bar")]
        )

        #expect(place?.name == "Loaded")
    }

    @Test("Without the map loaded, the copy saved for the alert is used, as in a cold launch from the tap")
    func fallsBackToSaved() {
        let place = ProximityAlertRouter.place(for: "bar", loaded: [], saved: [snapshot("bar")])

        #expect(place?.id == "bar")
        #expect(place?.name == "Saved")
        #expect(place?.latitude == -25.5)
        #expect(place?.distanceMeters == nil)
    }

    @Test("An unknown place cannot be opened")
    func unknown() {
        #expect(ProximityAlertRouter.place(for: "bar", loaded: [mapPlace("other")], saved: [snapshot("else")]) == nil)
    }
}
