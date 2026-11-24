import Foundation
import Testing
@testable import ZanzarProject

@Suite("ActiveItineraryFeed")
struct ActiveItineraryFeedTests {
    private func itinerary(_ slug: String) -> ActiveItinerary {
        ActiveItinerary(
            templateID: slug,
            slug: slug,
            name: slug,
            description: "",
            category: "history",
            routeType: .fixed,
            objectives: [],
            targetCategory: nil,
            targetCount: nil,
            startedAt: Date(timeIntervalSince1970: 1_000),
            places: []
        )
    }

    /// Collects what the feed hands to the coordinator. `nil` entries are "no active roteiro".
    private final class Applied: @unchecked Sendable {
        private let lock = NSLock()
        private var values: [String?] = []

        func append(_ itinerary: ActiveItinerary?) {
            lock.withLock { values.append(itinerary?.slug) }
        }

        var all: [String?] { lock.withLock { values } }
    }

    @Test("Hands the roteiro the server reports to the alerts")
    func appliesActive() async {
        let service = MockItineraryService(activeItineraryResult: .success(itinerary("centro")))
        let applied = Applied()
        let feed = ActiveItineraryFeed(service: service, userIDProvider: { "user-1" }, apply: applied.append)

        await feed.load()

        #expect(applied.all == ["centro"])
        #expect(service.fetchActiveItineraryUserID == "user-1")
    }

    @Test("No roteiro on the server clears it, so an abandoned roteiro stops alerting")
    func appliesNone() async {
        let service = MockItineraryService(activeItineraryResult: .success(nil))
        let applied = Applied()
        let feed = ActiveItineraryFeed(service: service, userIDProvider: { "user-1" }, apply: applied.append)

        await feed.load()

        #expect(applied.all == [nil])
    }

    @Test("Signed out: clears the roteiro without asking the server")
    func signedOut() async {
        let service = MockItineraryService(activeItineraryResult: .success(itinerary("centro")))
        let applied = Applied()
        let feed = ActiveItineraryFeed(service: service, userIDProvider: { nil }, apply: applied.append)

        await feed.load()

        #expect(applied.all == [nil])
        #expect(service.fetchActiveItineraryUserID == nil)
    }

    @Test("A failed request keeps the roteiro that was already known")
    func failureKeepsKnown() async {
        let service = MockItineraryService(activeItineraryResult: .failure(APIError.invalidResponse))
        let applied = Applied()
        let feed = ActiveItineraryFeed(service: service, userIDProvider: { "user-1" }, apply: applied.append)

        await feed.load()

        #expect(applied.all.isEmpty)
    }

    @Test("An answer that arrives after a newer refresh was made is dropped")
    func staleAnswerDropped() async throws {
        let service = GatedItineraryService(first: itinerary("old"), second: itinerary("new"))
        let applied = Applied()
        let feed = ActiveItineraryFeed(service: service, userIDProvider: { "user-1" }, apply: applied.append)

        let first = feed.refresh()
        for _ in 0..<100 where service.callCount < 1 {
            try await Task.sleep(for: .milliseconds(10))
        }
        let second = feed.refresh()
        await second.value
        service.openGate()
        await first.value

        #expect(applied.all == ["new"])
    }
}

/// The first `fetchActiveItinerary` waits until `openGate()`; later ones answer at once.
private final class GatedItineraryService: ItineraryServicing, @unchecked Sendable {
    private let lock = NSLock()
    private var calls = 0
    private let first: ActiveItinerary?
    private let second: ActiveItinerary?
    private let gate: AsyncStream<Void>
    private let release: AsyncStream<Void>.Continuation

    init(first: ActiveItinerary?, second: ActiveItinerary?) {
        self.first = first
        self.second = second
        (gate, release) = AsyncStream.makeStream(of: Void.self)
    }

    var callCount: Int { lock.withLock { calls } }

    func openGate() {
        release.yield()
    }

    func fetchActiveItinerary(userID: String) async throws -> ActiveItinerary? {
        let call = lock.withLock { () -> Int in
            calls += 1
            return calls
        }
        if call == 1 {
            for await _ in gate { break }
            return first
        }
        return second
    }

    func fetchItineraries() async throws -> [Itinerary] { [] }
    func fetchItineraryDetail(slug: String) async throws -> ItineraryDetail { throw APIError.invalidResponse }
    func activateItinerary(slug: String) async throws -> ActiveItinerary { throw APIError.invalidResponse }
    func abandonActiveItinerary() async throws {}
}
