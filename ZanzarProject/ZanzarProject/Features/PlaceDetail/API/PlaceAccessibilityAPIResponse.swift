import Foundation

/// `accessibility` in the place payloads: `{ features, source: { label, url }, checkedAt: "AAAA-MM-DD" }`.
nonisolated struct PlaceAccessibilityAPIResponse: Decodable, Sendable {
    let features: [String]
    let source: Source
    let checkedAt: String

    nonisolated struct Source: Decodable, Sendable {
        let label: String
        let url: String
    }

    /// Nil when the entry cannot be shown: no https source, a bad date, or no feature this app knows. A feature
    /// added by the backend later is skipped here instead of breaking the place.
    var accessibility: PlaceAccessibility? {
        let known = features.compactMap(PlaceAccessibilityFeature.init(rawValue:))
        guard !known.isEmpty,
              let url = PlaceImageAPIResponse.httpsURL(source.url),
              let date = Self.date(from: checkedAt)
        else { return nil }
        return PlaceAccessibility(features: known, sourceLabel: source.label, sourceURL: url, checkedAt: date)
    }

    private static func date(from string: String) -> Date? {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Sao_Paulo") ?? .current
        let parts = string.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        return calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2]))
    }
}
