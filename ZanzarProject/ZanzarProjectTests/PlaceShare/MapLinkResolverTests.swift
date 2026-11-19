import Foundation
import Testing
@testable import ZanzarProject

@Suite("MapLinkResolver")
struct MapLinkResolverTests {
    private static let short = URL(string: "https://maps.app.goo.gl/abc")!
    private static let long = URL(string: "https://www.google.com/maps/place/Padaria/@-25.4,-49.2,17z")!

    @Test("follows a short link to the map link it stands for")
    func followsShortLink() async {
        let fetcher = FakeRedirectFetcher(redirects: [Self.short: Self.long])
        let resolved = await MapLinkResolver(fetcher: fetcher).resolve(Self.short)
        #expect(resolved == Self.long)
    }

    @Test("follows a chain of short links")
    func followsChain() async {
        let middle = URL(string: "https://goo.gl/maps/xyz")!
        let fetcher = FakeRedirectFetcher(redirects: [Self.short: middle, middle: Self.long])
        let resolved = await MapLinkResolver(fetcher: fetcher).resolve(Self.short)
        #expect(resolved == Self.long)
    }

    @Test("a link that is not short is not fetched")
    func leavesLongLinkAlone() async {
        let fetcher = FakeRedirectFetcher(redirects: [:])
        let resolved = await MapLinkResolver(fetcher: fetcher).resolve(Self.long)
        #expect(resolved == Self.long)
        #expect(fetcher.fetched.isEmpty)
    }

    @Test("keeps the short link when it cannot be followed")
    func keepsLinkOnFailure() async {
        let fetcher = FakeRedirectFetcher(redirects: [:], fails: true)
        let resolved = await MapLinkResolver(fetcher: fetcher).resolve(Self.short)
        #expect(resolved == Self.short)
    }

    @Test("does not follow a redirect to somewhere that is not a map link")
    func refusesOtherHosts() async {
        let elsewhere = URL(string: "https://evil.example.com/steal")!
        let fetcher = FakeRedirectFetcher(redirects: [Self.short: elsewhere])
        let resolved = await MapLinkResolver(fetcher: fetcher).resolve(Self.short)
        #expect(resolved == Self.short)
        #expect(fetcher.fetched == [Self.short])
    }

    @Test("gives up after a few hops instead of looping")
    func stopsAfterMaxHops() async {
        let fetcher = FakeRedirectFetcher(redirects: [Self.short: Self.short])
        _ = await MapLinkResolver(fetcher: fetcher).resolve(Self.short)
        #expect(fetcher.fetched.count == MapLinkResolver.maxHops)
    }
}

final class FakeRedirectFetcher: RedirectFetching, @unchecked Sendable {
    private let redirects: [URL: URL]
    private let fails: Bool
    private(set) var fetched: [URL] = []

    init(redirects: [URL: URL], fails: Bool = false) {
        self.redirects = redirects
        self.fails = fails
    }

    func nextLocation(of url: URL) async throws -> URL? {
        fetched.append(url)
        if fails { throw URLError(.notConnectedToInternet) }
        return redirects[url]
    }
}
