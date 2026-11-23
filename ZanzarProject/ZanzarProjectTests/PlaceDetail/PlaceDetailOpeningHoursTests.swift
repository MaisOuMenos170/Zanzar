import Foundation
import Testing
@testable import ZanzarProject

@MainActor
@Suite("PlaceDetail opening hours")
struct PlaceDetailOpeningHoursTests {
    /// Wednesday 14:00 in Curitiba (UTC-3), the day the periods below are for.
    private static let wednesdayAfternoon = date("2026-11-25T17:00:00Z")
    /// The same day at 18:00 in Curitiba.
    private static let wednesdayClosing = date("2026-11-25T21:00:00Z")

    private static func date(_ iso: String) -> Date {
        ISO8601DateFormatter().date(from: iso) ?? .distantPast
    }

    private func makeDetail(openingHours: String, now: Date = wednesdayAfternoon) throws -> PlaceDetail {
        let json = """
        {
          "place_id": "place-1",
          "name": "Jardim Botânico",
          "opening_hours": \(openingHours),
          "geometry": { "location": { "lat": -25.44, "lng": -49.24 } },
          "photos": [],
          "zanzar": { "category": "park", "tags": [], "checkInCount": 1, "impressionCounts": {} }
        }
        """
        let response = try JSONDecoder().decode(PlaceDetailAPIResponse.self, from: Data(json.utf8))
        return PlaceDetail.make(
            placeResponse: response,
            mapPlace: MapPlace(
                id: "place-1", name: "Jardim Botânico", latitude: 0, longitude: 0, category: .park, distanceMeters: nil
            ),
            hasCheckedIn: false,
            selectedReactionTag: nil,
            now: now
        )
    }

    private static let wednesdayNineToSix = periods(open: "0900", close: "1800", openNow: false)

    private static func periods(open: String, close: String, openNow: Bool) -> String {
        """
        { "open_now": \(openNow), "periods": [
          { "open": { "day": 3, "time": "\(open)" }, "close": { "day": 3, "time": "\(close)" } } ] }
        """
    }

    @Test("says until when the place is open, from the periods")
    func openUntil() throws {
        let detail = try makeDetail(openingHours: Self.wednesdayNineToSix)

        #expect(detail.isOpen == true)
        #expect(detail.openingHoursText == L10n.string(
            "placeDetail.header.openUntil", PlaceDetail.closingTime(Self.wednesdayClosing)
        ))
    }

    @Test("is closed outside the periods, whatever the stored open_now says")
    func closedByPeriods() throws {
        let evening = Self.date("2026-11-25T23:00:00Z")
        let detail = try makeDetail(
            openingHours: Self.periods(open: "0900", close: "1800", openNow: true),
            now: evening
        )

        #expect(detail.isOpen == false)
        #expect(detail.openingHoursText == L10n.string("placeDetail.header.closedNow"))
    }

    @Test("a place that never closes is open 24 hours")
    func alwaysOpen() throws {
        let detail = try makeDetail(openingHours: #"{ "periods": [ { "open": { "day": 0, "time": "0000" } } ] }"#)

        #expect(detail.isOpen == true)
        #expect(detail.openingHoursText == L10n.string("placeDetail.header.open24Hours"))
    }

    @Test("falls back to open_now when there are no periods")
    func fallsBackToOpenNow() throws {
        let detail = try makeDetail(openingHours: #"{ "open_now": true }"#)

        #expect(detail.isOpen == true)
        #expect(detail.openingHoursText == L10n.string("placeDetail.header.openNow"))
    }

    @Test("malformed periods do not fail the whole detail")
    func malformedPeriods() throws {
        let detail = try makeDetail(openingHours: #"{ "open_now": false, "periods": "garbage" }"#)

        #expect(detail.isOpen == false)
    }
}
