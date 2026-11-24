import Foundation

/// Parses the ISO 8601 dates the backend sends, with or without fractional seconds.
nonisolated enum APIDate {
    static func parse(_ string: String) -> Date? {
        let withFraction = Date.ISO8601FormatStyle.iso8601.year().month().day().time(includingFractionalSeconds: true)
        if let date = try? Date(string, strategy: withFraction) {
            return date
        }
        return try? Date(string, strategy: .iso8601)
    }
}
