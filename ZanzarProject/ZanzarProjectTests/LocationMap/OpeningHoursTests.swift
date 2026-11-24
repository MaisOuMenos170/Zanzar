import Foundation
import Testing
@testable import ZanzarProject

@Suite("OpeningHours")
struct OpeningHoursTests {
    private static let timeZone = TimeZone(identifier: "America/Sao_Paulo")!

    /// 2026-11-06 is a Friday (Google day 5); 2026-11-08 is a Sunday (day 0).
    private func date(_ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = Self.timeZone
        return calendar.date(from: DateComponents(year: 2026, month: 11, day: day, hour: hour, minute: minute))!
    }

    private func hours(_ json: String) throws -> OpeningHours? {
        let response = try JSONDecoder().decode(PlaceOpeningHoursAPIResponse.self, from: Data(json.utf8))
        return OpeningHours(response: response)
    }

    private let museum = """
    {
      "open_now": true,
      "periods": [
        { "open": { "day": 2, "time": "1000" }, "close": { "day": 2, "time": "1730" } },
        { "open": { "day": 5, "time": "1000" }, "close": { "day": 5, "time": "1730" } }
      ]
    }
    """

    @Test("Open inside a period, closed outside it and on days without a period")
    func plainPeriod() throws {
        let hours = try #require(try hours(museum))

        #expect(hours.status(at: date(6, 12), in: Self.timeZone) == .open(closesAt: date(6, 17, 30)))
        #expect(hours.status(at: date(6, 9, 59), in: Self.timeZone) == .closed)
        #expect(hours.status(at: date(6, 17, 30), in: Self.timeZone) == .closed)
        #expect(hours.status(at: date(7, 12), in: Self.timeZone) == .closed)
    }

    @Test("The opening minute is open, the closing minute is not")
    func boundaries() throws {
        let hours = try #require(try hours(museum))

        #expect(hours.isOpen(at: date(6, 10), in: Self.timeZone))
        #expect(!hours.isOpen(at: date(6, 17, 30), in: Self.timeZone))
    }

    @Test("A bar that closes after midnight is open past midnight and reports tomorrow's closing")
    func overnight() throws {
        let bar = """
        { "periods": [
          { "open": { "day": 5, "time": "1800" }, "close": { "day": 6, "time": "0200" } }
        ] }
        """
        let hours = try #require(try hours(bar))

        #expect(hours.status(at: date(6, 23), in: Self.timeZone) == .open(closesAt: date(7, 2)))
        #expect(hours.status(at: date(7, 1), in: Self.timeZone) == .open(closesAt: date(7, 2)))
        #expect(hours.status(at: date(7, 2), in: Self.timeZone) == .closed)
        #expect(hours.status(at: date(6, 17), in: Self.timeZone) == .closed)
    }

    @Test("A period that wraps from Saturday night to Sunday morning is found across the week boundary")
    func weekWrap() throws {
        let club = """
        { "periods": [
          { "open": { "day": 6, "time": "2200" }, "close": { "day": 0, "time": "0500" } }
        ] }
        """
        let hours = try #require(try hours(club))

        // 2026-11-08 is a Sunday.
        #expect(hours.isOpen(at: date(8, 3), in: Self.timeZone))
        #expect(!hours.isOpen(at: date(8, 6), in: Self.timeZone))
    }

    @Test("A single open period with no close means open 24 hours, every day")
    func openAllDay() throws {
        let park = """
        { "periods": [ { "open": { "day": 0, "time": "0000" } } ] }
        """
        let hours = try #require(try hours(park))

        #expect(hours.status(at: date(6, 3), in: Self.timeZone) == .open(closesAt: nil))
        #expect(hours.status(at: date(9, 23, 59), in: Self.timeZone) == .open(closesAt: nil))
    }

    @Test("The time zone decides the local clock: the same instant is open in one zone and closed in another")
    func usesGivenTimeZone() throws {
        let hours = try #require(try hours(museum))
        // Friday 08:00 in Curitiba (UTC-3) is Friday 11:00 UTC.
        let instant = date(6, 8)

        #expect(!hours.isOpen(at: instant, in: Self.timeZone))
        #expect(hours.isOpen(at: instant, in: TimeZone(identifier: "UTC")!))
    }

    @Test("No hours when the payload has no periods, or only malformed ones")
    func missingOrMalformed() throws {
        #expect(try hours(#"{ "open_now": true }"#) == nil)
        #expect(try hours(#"{ "periods": [] }"#) == nil)
        #expect(try hours(#"{ "periods": [ { "open": { "day": 9, "time": "1000" } } ] }"#) == nil)
        #expect(try hours(#"{ "periods": [ { "open": { "day": 1, "time": "abc" } } ] }"#) == nil)
    }

    @Test("A malformed period is dropped without discarding the valid ones")
    func partiallyMalformed() throws {
        let json = """
        { "periods": [
          { "open": { "day": 1, "time": "zz" }, "close": { "day": 1, "time": "1700" } },
          { "open": { "day": 5, "time": "1000" }, "close": { "day": 5, "time": "1730" } }
        ] }
        """
        let hours = try #require(try hours(json))

        #expect(hours.isOpen(at: date(6, 12), in: Self.timeZone))
    }
}

@Suite("MapPlace opening hours")
struct MapPlaceOpeningHoursTests {
    @Test("GET /places opening_hours reaches the MapPlace")
    func decodesIntoMapPlace() throws {
        let json = """
        {
          "place_id": "p1",
          "name": "Museu",
          "geometry": { "location": { "lat": -25.4, "lng": -49.2 } },
          "zanzar": { "category": "museum" },
          "distanceMeters": 10,
          "opening_hours": {
            "open_now": false,
            "weekday_text": ["segunda-feira: Fechado"],
            "periods": [ { "open": { "day": 2, "time": "1000" }, "close": { "day": 2, "time": "1730" } } ]
          }
        }
        """
        let response = try JSONDecoder().decode(PlaceAPIResponse.self, from: Data(json.utf8))
        let place = MapPlace(response: response)

        #expect(place.openingHours != nil)
    }

    @Test("A place without opening_hours has none")
    func absentHours() throws {
        let json = """
        {
          "place_id": "p2",
          "name": "Praça",
          "geometry": { "location": { "lat": -25.4, "lng": -49.2 } },
          "zanzar": { "category": "park" },
          "distanceMeters": 10
        }
        """
        let response = try JSONDecoder().decode(PlaceAPIResponse.self, from: Data(json.utf8))

        #expect(MapPlace(response: response).openingHours == nil)
    }
}
