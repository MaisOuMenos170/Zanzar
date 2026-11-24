import Foundation
import Testing
@testable import ZanzarProject

@Suite("ProximityAlertContent")
struct ProximityAlertContentTests {
    private static let timeZone = TimeZone(identifier: "America/Sao_Paulo")!

    private func date(_ hour: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = Self.timeZone
        return calendar.date(from: DateComponents(year: 2026, month: 11, day: 6, hour: hour))!
    }

    private func snapshot(hours json: String?) throws -> ProximityPlaceSnapshot {
        let hours = try json.map { raw -> OpeningHours in
            let response = try JSONDecoder().decode(PlaceOpeningHoursAPIResponse.self, from: Data(raw.utf8))
            return try #require(OpeningHours(response: response))
        }
        return ProximityPlaceSnapshot(
            placeID: "bar",
            name: "Al Beek",
            latitude: 0,
            longitude: 0,
            openingHours: hours,
            hasCheckedIn: false,
            itineraryRunID: nil
        )
    }

    /// 22:00 on the test day as the alert prints it. The format follows the machine's locale ("22:00" or "10:00 PM"),
    /// so the tests compare against the same formatter instead of looking for digits.
    private var expectedClosingTime: String {
        date(22).formatted(Date.FormatStyle(date: .omitted, time: .shortened, timeZone: Self.timeZone))
    }

    private let openUntil22 = """
    { "periods": [ { "open": { "day": 5, "time": "1000" }, "close": { "day": 5, "time": "2200" } } ] }
    """

    @Test("The title is the place name and the body says until when it is open")
    func nearbyOpenUntil() throws {
        let content = ProximityAlertContent.make(
            for: try snapshot(hours: openUntil22),
            kind: .nearbyPlace,
            now: date(14),
            timeZone: Self.timeZone
        )

        #expect(content.title == "Al Beek")
        #expect(content.placeID == "bar")
        #expect(content.body == L10n.string("proximity.alert.nearby.body.openUntil", expectedClosingTime))
        #expect(content.body != L10n.string("proximity.alert.nearby.body"))
    }

    @Test("Unknown hours give a plain body with no time")
    func nearbyUnknownHours() throws {
        let content = ProximityAlertContent.make(
            for: try snapshot(hours: nil),
            kind: .nearbyPlace,
            now: date(14),
            timeZone: Self.timeZone
        )

        #expect(content.body == L10n.string("proximity.alert.nearby.body"))
    }

    @Test("A place open 24 hours says so")
    func nearbyOpenAllDay() throws {
        let content = ProximityAlertContent.make(
            for: try snapshot(hours: #"{ "periods": [ { "open": { "day": 0, "time": "0000" } } ] }"#),
            kind: .nearbyPlace,
            now: date(14),
            timeZone: Self.timeZone
        )

        #expect(content.body == L10n.string("proximity.alert.nearby.body.open24Hours"))
    }

    @Test("A roteiro stop is worded as the next stop")
    func stopBody() throws {
        let plain = ProximityAlertContent.make(
            for: try snapshot(hours: nil),
            kind: .itineraryStop,
            now: date(14),
            timeZone: Self.timeZone
        )
        let withHours = ProximityAlertContent.make(
            for: try snapshot(hours: openUntil22),
            kind: .itineraryStop,
            now: date(14),
            timeZone: Self.timeZone
        )

        #expect(plain.body == L10n.string("proximity.alert.stop.body"))
        #expect(withHours.body == L10n.string("proximity.alert.stop.body.openUntil", expectedClosingTime))
        #expect(withHours.kind == .itineraryStop)
    }
}
