import Foundation
import Testing
@testable import ZanzarProject

@Suite("ProximityAlertCoordinator")
struct ProximityAlertCoordinatorTests {
    private static let timeZone = TimeZone(identifier: "America/Sao_Paulo")!
    private let monitor = FakeProximityMonitor()
    private let notifier = FakeProximityNotifier()
    private let store = InMemoryProximityAlertStore()
    private let clock: TestClock
    private let coordinator: ProximityAlertCoordinator

    private let user = UserCoordinate(latitude: -25.4, longitude: -49.3)

    init() {
        // Friday 2026-11-06 14:00 in Curitiba.
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = Self.timeZone
        let start = calendar.date(from: DateComponents(year: 2026, month: 11, day: 6, hour: 14))!
        let clock = TestClock(start)
        self.clock = clock
        coordinator = ProximityAlertCoordinator(
            monitor: monitor,
            notifier: notifier,
            store: store,
            policy: ProximityAlertPolicy(timeZone: Self.timeZone),
            now: { clock.date }
        )
    }

    private func place(
        _ index: Int,
        style: LocationPinStyle = .available,
        openingHours: OpeningHours? = nil
    ) -> MapPlace {
        MapPlace(
            id: "p\(index)",
            name: "Place \(index)",
            latitude: -25.4,
            longitude: -49.3 + Double(index) * 0.001,
            category: .bar,
            distanceMeters: Double(index) * 100,
            pinStyle: style,
            openingHours: openingHours
        )
    }

    private func closedHours() throws -> OpeningHours {
        let json = """
        { "periods": [ { "open": { "day": 5, "time": "1800" }, "close": { "day": 5, "time": "2300" } } ] }
        """
        let response = try JSONDecoder().decode(PlaceOpeningHoursAPIResponse.self, from: Data(json.utf8))
        return try #require(OpeningHours(response: response))
    }

    private func itinerary(next placeID: String) -> ActiveItinerary {
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

    // MARK: Regions

    @Test("Watches the nearest places and saves them for a background relaunch")
    func watchesAndSaves() async {
        await coordinator.update(places: [place(2), place(1)], user: user)

        #expect(monitor.monitoredPlaceIDs == ["p1", "p2"])
        #expect(monitor.lastRadius == ProximityRegionSelector.radius)
        #expect(store.loadMonitoredPlaces().map(\.placeID) == ["p1", "p2"])
    }

    @Test("Without 'Always' location nothing is watched and the saved places are cleared")
    func notAuthorized() async {
        await coordinator.update(places: [place(1)], user: user)
        monitor.isAuthorized = false

        await coordinator.refresh()

        #expect(monitor.monitoredPlaceIDs.isEmpty)
        #expect(store.loadMonitoredPlaces().isEmpty)
    }

    @Test("Without notification permission nothing is watched")
    func notificationsNotAllowed() async {
        notifier.isAllowed = false

        await coordinator.update(places: [place(1)], user: user)

        #expect(monitor.monitorCallCount == 0)
        #expect(store.loadMonitoredPlaces().isEmpty)
    }

    @Test("With nearby alerts off only the roteiro stop is watched")
    func onlyStopWatched() async {
        var settings = ProximityAlertSettings()
        settings.nearbyPlacesEnabled = false
        store.saveSettings(settings)
        await coordinator.update(itinerary: itinerary(next: "p3"))

        await coordinator.update(places: [place(1), place(3)], user: user)

        #expect(monitor.monitoredPlaceIDs == ["p3"])
    }

    @Test("With everything off nothing is watched")
    func allOff() async {
        store.saveSettings(ProximityAlertSettings(nearbyPlacesEnabled: false, itineraryEnabled: false))
        await coordinator.update(itinerary: itinerary(next: "p3"))

        await coordinator.update(places: [place(1), place(3)], user: user)

        #expect(monitor.monitoredPlaceIDs.isEmpty)
        #expect(monitor.stopCallCount > 0)
    }

    @Test("Changing the roteiro re-chooses the regions with the places already known")
    func itineraryChangeResyncs() async {
        await coordinator.update(places: (1...25).map { place($0) }, user: user)
        #expect(!monitor.monitoredPlaceIDs.contains("p25"))

        await coordinator.update(itinerary: itinerary(next: "p25"))

        #expect(monitor.monitoredPlaceIDs.first == "p25")
    }

    @Test("Stopping forgets everything")
    func stopForgets() async {
        await coordinator.update(places: [place(1)], user: user)

        await coordinator.stop()

        #expect(monitor.monitoredPlaceIDs.isEmpty)
        #expect(store.loadMonitoredPlaces().isEmpty)
    }

    // MARK: Entries

    @Test("Coming close to a watched place posts its alert and records it")
    func entrySends() async {
        await coordinator.update(places: [place(1)], user: user)

        await coordinator.handleEntry(placeID: "p1")

        #expect(notifier.posted.map(\.title) == ["Place 1"])
        #expect(notifier.posted.first?.kind == .nearbyPlace)
        #expect(store.loadHistory().deliveries.map(\.placeID) == ["p1"])
    }

    @Test("The same place does not alert twice inside the cooldown")
    func entryCooldown() async {
        await coordinator.update(places: [place(1)], user: user)

        await coordinator.handleEntry(placeID: "p1")
        clock.advance(by: 3_600)
        await coordinator.handleEntry(placeID: "p1")

        #expect(notifier.posted.count == 1)
    }

    @Test("The third nearby alert of the day is held back")
    func entryDailyCap() async {
        await coordinator.update(places: [place(1), place(2), place(3)], user: user)

        await coordinator.handleEntry(placeID: "p1")
        await coordinator.handleEntry(placeID: "p2")
        await coordinator.handleEntry(placeID: "p3")

        #expect(notifier.posted.map(\.title) == ["Place 1", "Place 2"])
    }

    @Test("A place that is closed now is not announced, and is not recorded as announced")
    func entryClosed() async throws {
        await coordinator.update(places: [place(1, openingHours: try closedHours())], user: user)

        await coordinator.handleEntry(placeID: "p1")

        #expect(notifier.posted.isEmpty)
        #expect(store.loadHistory().deliveries.isEmpty)
    }

    @Test("An entry for a place that is not monitored is ignored")
    func entryUnknownPlace() async {
        await coordinator.update(places: [place(1)], user: user)

        await coordinator.handleEntry(placeID: "other")

        #expect(notifier.posted.isEmpty)
    }

    @Test("When posting fails the alert is not recorded, so it can try again later")
    func postFailureNotRecorded() async {
        await coordinator.update(places: [place(1)], user: user)
        notifier.failsToPost = true

        await coordinator.handleEntry(placeID: "p1")

        #expect(store.loadHistory().deliveries.isEmpty)

        notifier.failsToPost = false
        await coordinator.handleEntry(placeID: "p1")

        #expect(notifier.posted.count == 1)
    }

    @Test("The next stop of the roteiro is announced as a stop, once")
    func entryStop() async {
        await coordinator.update(itinerary: itinerary(next: "p2"))
        await coordinator.update(places: [place(1), place(2)], user: user)

        await coordinator.handleEntry(placeID: "p2")
        await coordinator.handleEntry(placeID: "p2")

        #expect(notifier.posted.count == 1)
        #expect(notifier.posted.first?.kind == .itineraryStop)
    }

    @Test("A stop with roteiro alerts off falls back to a plain nearby alert")
    func stopFallsBackToNearby() async {
        await coordinator.update(itinerary: itinerary(next: "p2"))
        await coordinator.update(places: [place(1), place(2)], user: user)
        store.saveSettings(ProximityAlertSettings(nearbyPlacesEnabled: true, itineraryEnabled: false))

        await coordinator.handleEntry(placeID: "p2")

        #expect(notifier.posted.first?.kind == .nearbyPlace)
    }

    @Test("Consuming the monitor's entries sends the alert")
    func listensToEntries() async throws {
        await coordinator.update(places: [place(1)], user: user)
        coordinator.start()

        monitor.enter("p1")

        for _ in 0..<50 where notifier.posted.isEmpty {
            try await Task.sleep(for: .milliseconds(20))
        }
        #expect(notifier.posted.map(\.title) == ["Place 1"])
    }
}
