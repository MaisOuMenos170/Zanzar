import Foundation

/// Reads what the share sheet hands over (text and links) and works out which place it points at.
/// Pure and offline: following a short link is `MapLinkResolver`'s job.
nonisolated enum MapLinkParser {
    // MARK: - Which links

    /// Google and Apple Maps links, long or short. The host is matched exactly, so `maps.app.goo.gl.evil.com`
    /// and `evilgoo.gl` are not map links.
    static func isMapLink(_ url: URL) -> Bool {
        isShortLink(url) || isGoogleMaps(url) || isAppleMaps(url)
    }

    /// Links that only redirect to the real map link (`maps.app.goo.gl/…`, `goo.gl/maps/…`, `maps.apple/p/…`).
    static func isShortLink(_ url: URL) -> Bool {
        guard isWeb(url), let host = url.host()?.lowercased() else { return false }
        return host == "maps.app.goo.gl"
            || (host == "goo.gl" && url.path.hasPrefix("/maps"))
            || (host == "maps.apple" && url.path.hasPrefix("/p/"))
    }

    // MARK: - What was shared

    /// The first map link in what was shared and the other lines of text, without any link.
    /// Google Maps shares "name, address, link" as text; Apple Maps shares a URL.
    static func read(texts: [String], urls: [URL]) -> (mapURL: URL?, lines: [String]) {
        let linksInText = texts.flatMap { text in
            text.matches(of: linkPattern).compactMap { URL(string: trimmedLink(String($0.output))) }
        }
        let mapURL = (urls + linksInText).first(where: isMapLink)
        let lines = texts
            .flatMap { $0.replacing(linkPattern, with: "").split(whereSeparator: \.isNewline) }
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        return (mapURL, lines)
    }

    /// The place a shared link and its accompanying text describe. With a link, the first text line is taken
    /// as the name and the rest as the address, but only where the link itself said nothing. Without one, the
    /// whole text is an address.
    static func hint(link: URL?, lines: [String]) -> SharedPlaceHint {
        guard let link else {
            return SharedPlaceHint(address: lines.isEmpty ? nil : lines.joined(separator: ", "))
        }
        var result = hint(from: link)
        if result.name == nil { result.name = lines.first }
        if result.address == nil, lines.count > 1 { result.address = lines.dropFirst().joined(separator: ", ") }
        return result
    }

    // MARK: - Reading a link

    static func hint(from url: URL) -> SharedPlaceHint {
        if isGoogleMaps(url) { return googleHint(from: url) }
        if isAppleMaps(url) { return appleHint(from: url) }
        return SharedPlaceHint()
    }

    private static func googleHint(from url: URL) -> SharedPlaceHint {
        let path = url.path
        let segments = url.pathComponents.filter { $0 != "/" }.map(plusDecoded)
        var hint = SharedPlaceHint()
        var viewport: SharedPlaceHint.Coordinate?
        var pin: SharedPlaceHint.Coordinate?

        // /maps/place/<name or lat,lng>/@lat,lng,17z/data=…!3d<lat>!4d<lng>
        if let index = segments.firstIndex(where: { $0 == "place" || $0 == "search" }),
           segments.indices.contains(index + 1), !segments[index + 1].hasPrefix("@") {
            let segment = segments[index + 1]
            if let found = parseCoordinate(in: segment) { pin = found } else { hint.name = nonEmpty(segment) }
        }
        if let viewportSegment = segments.first(where: { $0.hasPrefix("@") }) {
            viewport = parseCoordinate(in: String(viewportSegment.dropFirst()))
        }
        if let match = path.firstMatch(of: pinPattern) {
            pin = makeCoordinate(latitude: Double(match.1), longitude: Double(match.2))
        }

        let query = queryItems(of: url)
        if let text = query["q"] ?? query["query"] {
            if let found = parseCoordinate(in: text) {
                pin = pin ?? found
            } else {
                hint.name = hint.name ?? nonEmpty(text)
            }
        }
        let center = (query["ll"] ?? query["center"]).flatMap(parseCoordinate(in:))
        hint.coordinate = pin ?? center ?? viewport
        return hint
    }

    private static func appleHint(from url: URL) -> SharedPlaceHint {
        let query = queryItems(of: url)
        var hint = SharedPlaceHint()
        hint.address = query["address"].flatMap(nonEmpty)
        var position = (query["coordinate"] ?? query["ll"]).flatMap(parseCoordinate(in:))
        if let text = query["name"] ?? query["q"] {
            if let fromText = parseCoordinate(in: text) {
                position = position ?? fromText
            } else {
                hint.name = nonEmpty(text)
            }
        }
        hint.coordinate = position
        return hint
    }

    // MARK: - Pieces

    private static let linkPattern = /https?:\/\/\S+/
    /// The pin of a Google place: `!3d<latitude>!4d<longitude>` inside the `data` part of the path.
    private static let pinPattern = /!3d(-?\d+\.\d+)!4d(-?\d+\.\d+)/

    private static func isWeb(_ url: URL) -> Bool {
        url.scheme == "https" || url.scheme == "http"
    }

    private static func isGoogleMaps(_ url: URL) -> Bool {
        guard isWeb(url), let host = url.host()?.lowercased(),
              host.wholeMatch(of: /(www\.|maps\.)?google\.(com|com\.[a-z]{2}|co\.[a-z]{2}|[a-z]{2})/) != nil
        else { return false }
        return host.hasPrefix("maps.") || url.path.hasPrefix("/maps")
    }

    private static func isAppleMaps(_ url: URL) -> Bool {
        isWeb(url) && url.host()?.lowercased() == "maps.apple.com"
    }

    /// A link at the end of a sentence drags its punctuation along ("see https://… ).").
    private static func trimmedLink(_ link: String) -> String {
        link.trimmingCharacters(in: CharacterSet(charactersIn: ".,;:!?)>]\"'"))
    }

    private static func queryItems(of url: URL) -> [String: String] {
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        let pairs = items.compactMap { item in item.value.map { (item.name, plusDecoded($0)) } }
        return Dictionary(pairs) { first, _ in first }
    }

    /// Google writes spaces as `+` in paths and queries; the URL decoding leaves those alone.
    private static func plusDecoded(_ text: String) -> String {
        text.replacingOccurrences(of: "+", with: " ")
    }

    private static func nonEmpty(_ text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    /// "-25.4284,-49.2733" (more fields after the second are ignored, as in "-25.4,-49.2,17z").
    private static func parseCoordinate(in text: String) -> SharedPlaceHint.Coordinate? {
        let parts = text.split(separator: ",", omittingEmptySubsequences: false)
        guard parts.count >= 2,
              let latitude = Double(parts[0].trimmingCharacters(in: .whitespaces)),
              let longitude = Double(parts[1].trimmingCharacters(in: .whitespaces))
        else { return nil }
        return makeCoordinate(latitude: latitude, longitude: longitude)
    }

    /// Nil for an impossible position and for (0, 0), which is what a link with no position tends to carry.
    private static func makeCoordinate(latitude: Double?, longitude: Double?) -> SharedPlaceHint.Coordinate? {
        guard let latitude, let longitude,
              (-90...90).contains(latitude), (-180...180).contains(longitude),
              latitude != 0 || longitude != 0
        else { return nil }
        return SharedPlaceHint.Coordinate(latitude: latitude, longitude: longitude)
    }
}
