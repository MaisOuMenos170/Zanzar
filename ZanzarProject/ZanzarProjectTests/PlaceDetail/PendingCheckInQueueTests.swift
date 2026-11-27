import Foundation
import Testing
@testable import ZanzarProject

@MainActor
@Suite("PendingCheckInQueue")
struct PendingCheckInQueueTests {
    private static let time = Date(timeIntervalSince1970: 1_800_000_000)

    private static func item(
        _ placeID: String,
        user: String = "user-1",
        id: String? = nil,
        at offset: TimeInterval = 0
    ) -> PendingCheckIn {
        PendingCheckIn(
            id: id ?? "mutation-\(placeID)-\(user)",
            userID: user,
            placeID: placeID,
            placeName: "Lugar \(placeID)",
            latitude: -25.43,
            longitude: -49.27,
            accuracyMeters: 12,
            checkedInAt: time.addingTimeInterval(offset)
        )
    }

    private func makeQueue(
        items: [PendingCheckIn] = [],
        service: ScriptedCheckInService = ScriptedCheckInService(),
        user: String? = "user-1"
    ) -> (PendingCheckInQueue, InMemoryPendingCheckInStore, ScriptedCheckInService) {
        let store = InMemoryPendingCheckInStore(items: items)
        let queue = PendingCheckInQueue(store: store, service: service, userIDProvider: { user })
        return (queue, store, service)
    }

    @Test("a kept check-in is stored, and a second one for the same place replaces it")
    func enqueueKeepsOnePerPlace() {
        let (queue, store, _) = makeQueue()

        queue.enqueue(Self.item("a", id: "first"))
        queue.enqueue(Self.item("a", id: "second"))

        #expect(queue.count == 1)
        #expect(queue.contains(placeID: "a"))
        #expect(store.items.map(\.id) == ["second"])
    }

    @Test("it only shows and counts the signed-in user's check-ins, oldest first")
    func scopedToTheUser() {
        let (queue, _, _) = makeQueue(items: [
            Self.item("late", at: 60), Self.item("early", at: 0), Self.item("other", user: "user-2")
        ])

        #expect(queue.pending.map(\.placeID) == ["early", "late"])
        #expect(!queue.contains(placeID: "other"))
    }

    @Test("a signed-out session has nothing pending, and sends nothing")
    func signedOut() async {
        let (queue, _, service) = makeQueue(items: [Self.item("a")], user: nil)

        let result = await queue.flush()

        #expect(queue.count == 0)
        #expect(result == PendingCheckInQueue.FlushResult())
        #expect(service.calls.isEmpty)
    }

    @Test("flush sends each check-in with its own id and the time the user tapped, then forgets it")
    func flushSends() async {
        let service = ScriptedCheckInService(results: [.success(PlaceDetailFixture.checkInResult)])
        let (queue, store, _) = makeQueue(items: [Self.item("a", id: "mutation-a", at: 30)], service: service)

        let result = await queue.flush()

        #expect(result.sent.map(\.placeID) == ["a"])
        #expect(result.remaining == 0)
        #expect(service.calls.map(\.mutationID) == ["mutation-a"])
        #expect(service.calls.map(\.datetime) == [Self.time.addingTimeInterval(30)])
        #expect(store.items.isEmpty)
    }

    @Test("a 409 means the server already has it: it counts as sent")
    func conflictIsSent() async {
        let service = ScriptedCheckInService(results: [.failure(APIError.httpStatus(409, message: nil))])
        let (queue, store, _) = makeQueue(items: [Self.item("a")], service: service)

        let result = await queue.flush()

        #expect(result.sent.count == 1)
        #expect(store.items.isEmpty)
    }

    @Test("a 422 means the server refused it for good: it is dropped and reported")
    func refusedIsDropped() async {
        let service = ScriptedCheckInService(results: [.failure(APIError.httpStatus(422, message: nil))])
        let (queue, store, _) = makeQueue(items: [Self.item("a")], service: service)

        let result = await queue.flush()

        #expect(result.refused.map(\.placeID) == ["a"])
        #expect(result.sent.isEmpty)
        #expect(store.items.isEmpty)
    }

    @Test("no network keeps everything and stops at the first failure")
    func offlineKeepsAndStops() async {
        let service = ScriptedCheckInService(results: [.failure(URLError(.notConnectedToInternet))])
        let (queue, store, _) = makeQueue(items: [Self.item("a", at: 0), Self.item("b", at: 10)], service: service)

        let result = await queue.flush()

        #expect(result.sent.isEmpty)
        #expect(result.remaining == 2)
        #expect(service.calls.count == 1)
        #expect(store.items.count == 2)
    }

    @Test("it goes on after one is sent, and keeps the one that fails")
    func partialFlush() async {
        let service = ScriptedCheckInService(results: [
            .success(PlaceDetailFixture.checkInResult), .failure(APIError.httpStatus(500, message: nil))
        ])
        let (queue, _, _) = makeQueue(items: [Self.item("a", at: 0), Self.item("b", at: 10)], service: service)

        let result = await queue.flush()

        #expect(result.sent.map(\.placeID) == ["a"])
        #expect(result.remaining == 1)
        #expect(queue.contains(placeID: "b"))
    }

    @Test("leaving on purpose drops only this user's check-ins")
    func discardPendingIsScoped() {
        let (queue, store, _) = makeQueue(items: [Self.item("a"), Self.item("b", user: "user-2")])

        queue.discardPending()

        #expect(queue.count == 0)
        #expect(store.items.map(\.userID) == ["user-2"])
    }

    @Test("another account's check-ins are not sent while this one is signed in")
    func otherAccountsAreLeftAlone() async {
        let service = ScriptedCheckInService(results: [.success(PlaceDetailFixture.checkInResult)])
        let items = [Self.item("mine"), Self.item("theirs", user: "user-2")]
        let (queue, store, _) = makeQueue(items: items, service: service)

        await queue.flush()

        #expect(service.calls.map(\.placeID) == ["mine"])
        #expect(store.items.map(\.placeID) == ["theirs"])
    }
}

/// Answers each check-in with the next scripted result (the last one repeats).
final class ScriptedCheckInService: PlaceDetailServicing, @unchecked Sendable {
    struct Call { let placeID: String; let mutationID: String; let datetime: Date }

    private var results: [Result<CheckInResult, Error>]
    private(set) var calls: [Call] = []

    init(results: [Result<CheckInResult, Error>] = [.success(PlaceDetailFixture.checkInResult)]) {
        self.results = results
    }

    func fetchPlaceDetail(context: PlaceDetailLoadContext) async throws -> PlaceDetail {
        fatalError("not used")
    }

    func checkIn(
        placeID: String,
        coordinate: UserCoordinate,
        mutationID: String,
        datetime: Date
    ) async throws -> CheckInResult {
        calls.append(Call(placeID: placeID, mutationID: mutationID, datetime: datetime))
        let result = results.count > 1 ? results.removeFirst() : results[0]
        return try result.get()
    }
}
