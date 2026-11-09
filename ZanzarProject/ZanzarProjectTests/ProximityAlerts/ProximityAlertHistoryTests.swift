import Foundation
import Testing
@testable import ZanzarProject

@Suite("ProximityAlertHistory")
struct ProximityAlertHistoryTests {
    private static let day: TimeInterval = 24 * 3_600
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    @Test("Recording a nearby alert adds a delivery")
    func recordsNearby() {
        var history = ProximityAlertHistory()
        let candidate = ProximityAlertCandidate(
            placeID: "bar",
            kind: .nearbyPlace,
            openingHours: nil,
            hasCheckedIn: false
        )

        history.record(candidate, at: now)

        #expect(history.deliveries == [.init(placeID: "bar", kind: .nearbyPlace, date: now)])
        #expect(history.notifiedStopKeys.isEmpty)
    }

    @Test("Recording a roteiro stop adds a delivery and remembers the stop for that run")
    func recordsStop() {
        var history = ProximityAlertHistory()
        let candidate = ProximityAlertCandidate(
            placeID: "bar",
            kind: .itineraryStop(runID: "run-1"),
            openingHours: nil,
            hasCheckedIn: false
        )

        history.record(candidate, at: now)

        #expect(history.deliveries == [.init(placeID: "bar", kind: .itineraryStop, date: now)])
        #expect(history.notifiedStopKeys == [ProximityAlertHistory.stopKey(runID: "run-1", placeID: "bar")])
    }

    @Test("Pruning drops deliveries older than the cooldown and stops from other runs")
    func prunes() {
        let history = ProximityAlertHistory(
            deliveries: [
                .init(placeID: "old", kind: .nearbyPlace, date: now.addingTimeInterval(-4 * Self.day)),
                .init(placeID: "recent", kind: .nearbyPlace, date: now.addingTimeInterval(-1 * Self.day))
            ],
            notifiedStopKeys: [
                ProximityAlertHistory.stopKey(runID: "run-1", placeID: "a"),
                ProximityAlertHistory.stopKey(runID: "run-2", placeID: "b")
            ]
        )

        let pruned = history.pruned(now: now, keepingRun: "run-2", retention: 3 * Self.day)

        #expect(pruned.deliveries.map(\.placeID) == ["recent"])
        #expect(pruned.notifiedStopKeys == [ProximityAlertHistory.stopKey(runID: "run-2", placeID: "b")])
    }

    @Test("Pruning without an active run forgets every stop")
    func prunesAllStopsWhenNoRun() {
        let history = ProximityAlertHistory(
            deliveries: [],
            notifiedStopKeys: [ProximityAlertHistory.stopKey(runID: "run-1", placeID: "a")]
        )

        #expect(history.pruned(now: now, keepingRun: nil, retention: 3 * Self.day).notifiedStopKeys.isEmpty)
    }

    @Test("History survives a round trip through the store")
    func storeRoundTrip() {
        let store = InMemoryProximityAlertStore()
        var history = ProximityAlertHistory()
        history.record(
            ProximityAlertCandidate(placeID: "bar", kind: .nearbyPlace, openingHours: nil, hasCheckedIn: false),
            at: now
        )

        store.saveHistory(history)

        #expect(store.loadHistory() == history)
    }

    @Test("Settings default to everything on and are kept by the store")
    func settingsDefaultsAndStore() {
        let store = InMemoryProximityAlertStore()
        #expect(store.loadSettings() == ProximityAlertSettings())
        #expect(ProximityAlertSettings().nearbyPlacesEnabled)
        #expect(ProximityAlertSettings().itineraryEnabled)

        var changed = ProximityAlertSettings()
        changed.nearbyPlacesEnabled = false
        store.saveSettings(changed)

        #expect(store.loadSettings() == changed)
    }
}

@Suite("ActiveItinerary next stop")
struct ActiveItineraryNextStopTests {
    private func itinerary(_ slots: [ItinerarySlot]) -> ActiveItinerary {
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
            places: slots
        )
    }

    private func slot(_ id: String, place: String?, done: Bool) -> ItinerarySlot {
        ItinerarySlot(
            id: id,
            placeID: place,
            placeName: place,
            isCompleted: done,
            completedAt: done ? Date(timeIntervalSince1970: 2_000) : nil,
            stampID: nil
        )
    }

    @Test("The next stop is the first uncompleted slot that has a place")
    func nextStop() {
        let active = itinerary([
            slot("1", place: "a", done: true),
            slot("2", place: nil, done: false),
            slot("3", place: "c", done: false),
            slot("4", place: "d", done: false)
        ])

        #expect(active.nextPendingPlaceID == "c")
    }

    @Test("There is no next stop once everything is done")
    func noNextStop() {
        let active = itinerary([slot("1", place: "a", done: true)])

        #expect(active.nextPendingPlaceID == nil)
    }

    @Test("The run id changes when the same roteiro is started again")
    func runID() {
        let first = itinerary([])
        let second = ActiveItinerary(
            templateID: first.templateID,
            slug: first.slug,
            name: first.name,
            description: "",
            category: first.category,
            routeType: first.routeType,
            objectives: [],
            targetCategory: nil,
            targetCount: nil,
            startedAt: Date(timeIntervalSince1970: 5_000),
            places: []
        )

        #expect(first.runID != second.runID)
    }
}
