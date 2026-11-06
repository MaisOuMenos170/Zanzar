import Foundation
import Testing
@testable import ZanzarProject

@Suite("ProximityAlertPolicy")
struct ProximityAlertPolicyTests {
    private static let timeZone = TimeZone(identifier: "America/Sao_Paulo")!
    private static let hour: TimeInterval = 3_600
    private static let day: TimeInterval = 24 * hour

    private let policy = ProximityAlertPolicy()
    private let settings = ProximityAlertSettings()
    /// A Friday, 2026-11-06 14:00 in Curitiba.
    private let now = localDate(6, 14)

    private static func localDate(_ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar.date(from: DateComponents(year: 2026, month: 11, day: day, hour: hour, minute: minute))!
    }

    private func hours(_ json: String) throws -> OpeningHours {
        let response = try JSONDecoder().decode(PlaceOpeningHoursAPIResponse.self, from: Data(json.utf8))
        return try #require(OpeningHours(response: response))
    }

    private func nearby(
        _ placeID: String = "bar",
        openingHours: OpeningHours? = nil,
        hasCheckedIn: Bool = false
    ) -> ProximityAlertCandidate {
        ProximityAlertCandidate(
            placeID: placeID,
            kind: .nearbyPlace,
            openingHours: openingHours,
            hasCheckedIn: hasCheckedIn
        )
    }

    private func stop(
        _ placeID: String = "bar",
        run: String = "run-1",
        openingHours: OpeningHours? = nil,
        hasCheckedIn: Bool = false
    ) -> ProximityAlertCandidate {
        ProximityAlertCandidate(
            placeID: placeID,
            kind: .itineraryStop(runID: run),
            openingHours: openingHours,
            hasCheckedIn: hasCheckedIn
        )
    }

    private func history(
        _ deliveries: [ProximityAlertHistory.Delivery] = [],
        stops: Set<String> = []
    ) -> ProximityAlertHistory {
        ProximityAlertHistory(deliveries: deliveries, notifiedStopKeys: stops)
    }

    /// An alert about `placeID` sent `ago` seconds before `now`.
    private func sent(
        _ placeID: String,
        _ kind: ProximityAlertDeliveryKind = .nearbyPlace,
        ago: TimeInterval
    ) -> ProximityAlertHistory.Delivery {
        ProximityAlertHistory.Delivery(placeID: placeID, kind: kind, date: now.addingTimeInterval(-ago))
    }

    private func decide(
        _ candidate: ProximityAlertCandidate,
        settings: ProximityAlertSettings? = nil,
        history: ProximityAlertHistory? = nil
    ) -> ProximityAlertPolicy.Decision {
        policy.decide(candidate, settings: settings ?? self.settings, history: history ?? self.history(), now: now)
    }

    // MARK: Nearby places

    @Test("A nearby place is sent when nothing stands in the way")
    func nearbySent() {
        #expect(decide(nearby()) == .send)
    }

    @Test("Nothing is sent when the user turned nearby places off")
    func nearbyDisabled() {
        var off = settings
        off.nearbyPlacesEnabled = false

        #expect(decide(nearby(), settings: off) == .skip(.disabled))
    }

    @Test("A place the user already checked in to is never announced")
    func nearbyCheckedIn() {
        #expect(decide(nearby(hasCheckedIn: true)) == .skip(.alreadyCheckedIn))
    }

    @Test("A closed place is skipped; an open one and one with unknown hours are sent")
    func nearbyOpenness() throws {
        let museum = try hours("""
        { "periods": [ { "open": { "day": 5, "time": "1000" }, "close": { "day": 5, "time": "1730" } } ] }
        """)
        let closedNow = try hours("""
        { "periods": [ { "open": { "day": 5, "time": "1800" }, "close": { "day": 5, "time": "2300" } } ] }
        """)

        #expect(decide(nearby(openingHours: museum)) == .send)
        #expect(decide(nearby(openingHours: closedNow)) == .skip(.closed))
        #expect(decide(nearby(openingHours: nil)) == .send)
    }

    @Test("Someone out at 2am is told about a bar that is open, with no fixed quiet hours")
    func nearbyAtNight() throws {
        let bar = try hours("""
        { "periods": [ { "open": { "day": 5, "time": "1800" }, "close": { "day": 6, "time": "0400" } } ] }
        """)
        let twoAM = Self.localDate(7, 2)

        let decision = policy.decide(nearby(openingHours: bar), settings: settings, history: history(), now: twoAM)

        #expect(decision == .send)
    }

    @Test("At most two nearby alerts in any rolling 24 hours")
    func nearbyDailyCap() {
        let recent = [
            sent("a", ago: 2 * Self.hour),
            sent("b", ago: 10 * Self.hour)
        ]

        #expect(decide(nearby("c"), history: history(recent)) == .skip(.dailyLimitReached))
    }

    @Test("An alert older than 24 hours no longer counts toward the cap, even across midnight")
    func nearbyCapIsRolling() {
        let deliveries = [
            sent("a", ago: 25 * Self.hour),
            sent("b", ago: 3 * Self.hour)
        ]

        #expect(decide(nearby("c"), history: history(deliveries)) == .send)
    }

    @Test("The same place is not announced again for three days, then it is")
    func nearbyCooldown() {
        let twoDaysAgo = [sent("bar", ago: 2 * Self.day)]
        let fourDaysAgo = [sent("bar", ago: 4 * Self.day)]

        #expect(decide(nearby("bar"), history: history(twoDaysAgo)) == .skip(.cooldown))
        #expect(decide(nearby("bar"), history: history(fourDaysAgo)) == .send)
    }

    @Test("A roteiro alert also starts the cooldown, so the same place is not announced twice")
    func nearbyCooldownAfterStopAlert() {
        let earlier = [sent("bar", .itineraryStop, ago: Self.hour)]

        #expect(decide(nearby("bar"), history: history(earlier)) == .skip(.cooldown))
    }

    @Test("Roteiro alerts do not use up the nearby daily cap")
    func stopAlertsDoNotCountTowardCap() {
        let stops = [
            sent("a", .itineraryStop, ago: Self.hour),
            sent("b", .itineraryStop, ago: 2 * Self.hour),
            sent("c", .itineraryStop, ago: 3 * Self.hour)
        ]

        #expect(decide(nearby("d"), history: history(stops)) == .send)
    }

    // MARK: Roteiro stops

    @Test("A roteiro stop is sent the first time")
    func stopSent() {
        #expect(decide(stop()) == .send)
    }

    @Test("A roteiro stop is announced once per run, and again in a new run")
    func stopOncePerRun() {
        let notified = history(stops: [ProximityAlertHistory.stopKey(runID: "run-1", placeID: "bar")])

        #expect(decide(stop(run: "run-1"), history: notified) == .skip(.stopAlreadyAnnounced))
        #expect(decide(stop(run: "run-2"), history: notified) == .send)
    }

    @Test("Roteiro alerts ignore the nearby cap and cooldown")
    func stopIgnoresNearbyLimits() {
        let busy = [
            sent("x", ago: Self.hour),
            sent("y", ago: 2 * Self.hour),
            sent("bar", ago: Self.hour)
        ]

        #expect(decide(stop("bar"), history: history(busy)) == .send)
    }

    @Test("Roteiro alerts follow their own toggle, not the nearby one")
    func stopToggle() {
        var onlyNearby = settings
        onlyNearby.itineraryEnabled = false
        var onlyItinerary = settings
        onlyItinerary.nearbyPlacesEnabled = false

        #expect(decide(stop(), settings: onlyNearby) == .skip(.disabled))
        #expect(decide(stop(), settings: onlyItinerary) == .send)
    }

    @Test("A closed roteiro stop is skipped and stays eligible for a later pass")
    func stopClosed() throws {
        let closedNow = try hours("""
        { "periods": [ { "open": { "day": 5, "time": "1800" }, "close": { "day": 5, "time": "2300" } } ] }
        """)

        #expect(decide(stop(openingHours: closedNow)) == .skip(.closed))
        #expect(decide(stop(hasCheckedIn: true)) == .skip(.alreadyCheckedIn))
    }
}
