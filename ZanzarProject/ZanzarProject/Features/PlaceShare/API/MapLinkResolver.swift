import Foundation

/// Asks a link where it redirects to, without following it.
nonisolated protocol RedirectFetching: Sendable {
    func nextLocation(of url: URL) async throws -> URL?
}

/// Turns a short map link (`maps.app.goo.gl/…`) into the long one the parser can read. Every step has to land on a
/// Google or Apple Maps link, so a shared link cannot make the extension go somewhere else.
nonisolated struct MapLinkResolver: Sendable {
    static let maxHops = 5

    private let fetcher: RedirectFetching

    init(fetcher: RedirectFetching = URLSessionRedirectFetcher()) {
        self.fetcher = fetcher
    }

    /// `url` itself when it is not short or cannot be followed: the shared text may still say what the place is.
    func resolve(_ url: URL) async -> URL {
        var current = url
        for _ in 0..<Self.maxHops {
            guard MapLinkParser.isShortLink(current) else { return current }
            guard let next = try? await fetcher.nextLocation(of: current), MapLinkParser.isMapLink(next) else {
                return current
            }
            current = next
        }
        return current
    }
}

nonisolated struct URLSessionRedirectFetcher: RedirectFetching {
    private static let timeout: TimeInterval = 8

    func nextLocation(of url: URL) async throws -> URL? {
        let request = URLRequest(url: url, timeoutInterval: Self.timeout)
        let (_, response) = try await URLSession.shared.data(for: request, delegate: StopAtRedirect())
        guard let http = response as? HTTPURLResponse, (300..<400).contains(http.statusCode),
              let location = http.value(forHTTPHeaderField: "Location") else { return nil }
        return URL(string: location, relativeTo: url)?.absoluteURL
    }
}

/// Answers a redirect with "no", so the response that asked for it (and its `Location`) is what comes back.
private nonisolated final class StopAtRedirect: NSObject, URLSessionTaskDelegate {
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest,
        completionHandler: @escaping (URLRequest?) -> Void
    ) {
        completionHandler(nil)
    }
}
