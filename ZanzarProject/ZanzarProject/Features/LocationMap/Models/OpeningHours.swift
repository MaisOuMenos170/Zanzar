import Foundation

/// The weekly opening hours of a place, as Google Places sends them (`opening_hours.periods`).
///
/// `open_now` from the payload is deliberately ignored: it is a snapshot from when the place was stored,
/// so "is it open?" is always computed from the periods and the current time.
nonisolated struct OpeningHours: Codable, Hashable, Sendable {
    nonisolated struct Moment: Codable, Hashable, Sendable {
        /// 0 = Sunday ... 6 = Saturday, like Google Places.
        let day: Int
        let minuteOfDay: Int

        fileprivate var minuteOfWeek: Int {
            day * OpeningHours.minutesPerDay + minuteOfDay
        }
    }

    nonisolated struct Period: Codable, Hashable, Sendable {
        let open: Moment
        /// `nil` means the place never closes (Google sends a single Sunday 00:00 period without `close`).
        let close: Moment?
    }

    nonisolated enum Status: Hashable, Sendable {
        /// `closesAt` is `nil` for places that are open 24 hours.
        case open(closesAt: Date?)
        case closed
    }

    fileprivate static let minutesPerDay = 24 * 60
    fileprivate static let minutesPerWeek = 7 * minutesPerDay

    /// Curitiba. The periods are wall-clock times in the place's own zone.
    static let defaultTimeZone = TimeZone(identifier: "America/Sao_Paulo") ?? .current

    let periods: [Period]

    init?(periods: [Period]) {
        guard !periods.isEmpty else { return nil }
        self.periods = periods
    }

    func isOpen(at date: Date, in timeZone: TimeZone = defaultTimeZone) -> Bool {
        if case .open = status(at: date, in: timeZone) { return true }
        return false
    }

    func status(at date: Date, in timeZone: TimeZone = defaultTimeZone) -> Status {
        let now = Self.minuteOfWeek(of: date, in: timeZone)
        var closesInMinutes: Int?
        var alwaysOpen = false

        for period in periods {
            guard let close = period.close else {
                alwaysOpen = true
                continue
            }
            let start = period.open.minuteOfWeek
            var end = close.minuteOfWeek
            if end <= start { end += Self.minutesPerWeek }

            // The period may have started last week (it wraps over Saturday night), so test `now` and `now + week`.
            for candidate in [now, now + Self.minutesPerWeek] where start <= candidate && candidate < end {
                let remaining = end - candidate
                closesInMinutes = min(closesInMinutes ?? remaining, remaining)
            }
        }

        if let closesInMinutes {
            let startOfMinute = Self.startOfMinute(date, in: timeZone)
            return .open(closesAt: startOfMinute.addingTimeInterval(TimeInterval(closesInMinutes * 60)))
        }
        return alwaysOpen ? .open(closesAt: nil) : .closed
    }

    private static func calendar(in timeZone: TimeZone) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }

    private static func minuteOfWeek(of date: Date, in timeZone: TimeZone) -> Int {
        let components = calendar(in: timeZone).dateComponents([.weekday, .hour, .minute], from: date)
        // Calendar weekday is 1 = Sunday ... 7 = Saturday.
        let day = (components.weekday ?? 1) - 1
        return day * minutesPerDay + (components.hour ?? 0) * 60 + (components.minute ?? 0)
    }

    /// `date` with seconds dropped, so the closing time lands on an exact minute.
    private static func startOfMinute(_ date: Date, in timeZone: TimeZone) -> Date {
        let calendar = calendar(in: timeZone)
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        return calendar.date(from: components) ?? date
    }
}

nonisolated struct PlaceOpeningHoursAPIResponse: Decodable, Sendable {
    let periods: [PeriodResponse]?

    nonisolated struct PeriodResponse: Decodable, Sendable {
        let open: MomentResponse
        let close: MomentResponse?
    }

    nonisolated struct MomentResponse: Decodable, Sendable {
        let day: Int
        /// "HHmm", e.g. "1730".
        let time: String
    }
}

extension OpeningHours {
    /// `nil` when the payload carries no usable period. A malformed period is skipped, not fatal.
    init?(response: PlaceOpeningHoursAPIResponse) {
        let periods = (response.periods ?? []).compactMap { period -> Period? in
            guard let open = Moment(response: period.open) else { return nil }
            guard let rawClose = period.close else { return Period(open: open, close: nil) }
            guard let close = Moment(response: rawClose) else { return nil }
            return Period(open: open, close: close)
        }
        self.init(periods: periods)
    }
}

extension OpeningHours.Moment {
    fileprivate init?(response: PlaceOpeningHoursAPIResponse.MomentResponse) {
        guard (0...6).contains(response.day),
              response.time.count == 4,
              let hhmm = Int(response.time) else { return nil }
        let hour = hhmm / 100
        let minute = hhmm % 100
        guard hour < 24 || (hour == 24 && minute == 0), minute < 60 else { return nil }
        self.init(day: response.day, minuteOfDay: hour * 60 + minute)
    }
}
