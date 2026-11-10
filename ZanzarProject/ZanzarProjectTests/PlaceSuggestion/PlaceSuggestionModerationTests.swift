import Foundation
import Testing
@testable import ZanzarProject

@MainActor
@Suite("Place suggestion search, status and notices")
struct PlaceSuggestionModerationTests {
    private static let garden = SuggestedPlace(
        osmType: "way", osmID: 42, name: "Jardim Botânico", address: "Curitiba", latitude: -25.44, longitude: -49.24
    )

    // MARK: Service

    private static let searchJSON = """
    [
      { "osmType": "way", "osmId": 42, "name": "Jardim Botânico", "address": "Curitiba",
        "latitude": -25.44, "longitude": -49.24, "category": "park" },
      { "osmType": "node", "osmId": 7, "name": "Ponto de ônibus", "address": "Curitiba",
        "latitude": -25.4, "longitude": -49.2, "category": null },
      { "osmType": "planet", "osmId": 8, "name": "Estranho", "address": "Curitiba",
        "latitude": -25.4, "longitude": -49.2, "category": "cafe" }
    ]
    """

    private static let createdJSON = """
    {
      "_id": "665f1c2e8a1b2c3d4e5f6a7b", "status": "approved", "name": "Jardim Botânico",
      "address": "Curitiba", "coordinates": { "latitude": -25.44, "longitude": -49.24 },
      "note": "Lindo", "decisionReason": null, "placeId": "osm:way/42",
      "createdAt": "2026-11-09T12:00:00.000Z", "decidedAt": "2026-11-09T12:00:00.100Z"
    }
    """

    @Test("search sends the text and the position, and keeps only places the app can suggest")
    func searchRequestAndFiltering() async throws {
        let client = CapturingNetworkClient(json: Self.searchJSON)
        let service = PlaceSuggestionService(client: client)
        let near = SuggestedLocation(latitude: -25.43, longitude: -49.27, address: "x")

        let places = try await service.searchPlaces(query: "jardim", near: near)

        #expect(client.lastGetPath == "place-suggestions/search")
        let items = Dictionary(uniqueKeysWithValues: (client.lastQueryItems).map { ($0.name, $0.value) })
        #expect(items["q"] == "jardim")
        #expect(items["lat"] == "-25.43")
        #expect(items["lng"] == "-49.27")
        // The bus stop has no category and the third has an unknown OpenStreetMap type.
        #expect(places.map(\.id) == ["way/42"])
    }

    @Test("search without a position sends only the text")
    func searchWithoutPosition() async throws {
        let client = CapturingNetworkClient(json: "[]")
        let service = PlaceSuggestionService(client: client)

        _ = try await service.searchPlaces(query: "jardim", near: nil)

        #expect(client.lastQueryItems.map(\.name) == ["q"])
    }

    @Test("submitting a found place sends only its OpenStreetMap id and the trimmed note")
    func submitPlaceBody() async throws {
        let client = CapturingNetworkClient(json: Self.createdJSON)
        let service = PlaceSuggestionService(client: client)

        let suggestion = try await service.submit(Self.garden, note: "  Lindo \n")

        #expect(client.lastSendPath == "place-suggestions")
        #expect(client.lastSendMethod == .post)
        let body = try #require(client.lastBodyJSON)
        #expect(body["osmType"] as? String == "way")
        #expect(body["osmId"] as? Int == 42)
        #expect(body["note"] as? String == "Lindo")
        #expect(body["name"] == nil)
        #expect(body["coordinates"] == nil)
        #expect(suggestion.status == .approved)
        #expect(suggestion.placeID == "osm:way/42")
    }

    @Test("a blank note is left out")
    func submitPlaceBlankNote() async throws {
        let client = CapturingNetworkClient(json: Self.createdJSON)
        let service = PlaceSuggestionService(client: client)

        _ = try await service.submit(Self.garden, note: "  ")

        #expect(try #require(client.lastBodyJSON)["note"] == nil)
    }

    @Test("fetchMine maps statuses, reasons and dates")
    func fetchMineMapping() async throws {
        let json = """
        [
          { "_id": "a", "status": "rejected", "name": "Padaria", "address": "Rua A", "note": null,
            "decisionReason": "duplicate", "placeId": "osm:node/1",
            "createdAt": "2026-11-09T12:00:00.000Z", "decidedAt": "2026-11-09T12:00:00.000Z" },
          { "_id": "b", "status": "needs_review", "name": null, "address": "Rua B", "note": "oi",
            "decisionReason": "manual_entry", "placeId": null,
            "createdAt": "2026-11-08T12:00:00Z", "decidedAt": null },
          { "_id": "c", "status": "something_new", "name": null, "address": "Rua C", "note": null,
            "decisionReason": null, "placeId": null, "createdAt": "2026-11-07T12:00:00Z", "decidedAt": null }
        ]
        """
        let service = PlaceSuggestionService(client: CapturingNetworkClient(json: json))

        let suggestions = try await service.fetchMine()

        #expect(suggestions.map(\.status) == [.rejected, .needsReview, .needsReview])
        #expect(suggestions[0].decisionReason == .duplicate)
        #expect(suggestions[0].placeID == "osm:node/1")
        #expect(suggestions[1].name == nil)
        #expect(suggestions[1].displayName == "Rua B")
        #expect(suggestions[1].decisionReason == .other("manual_entry"))
        #expect(suggestions[1].decidedAt == nil)
        #expect(suggestions[0].createdAt == Date(timeIntervalSince1970: 1_794_225_600))
    }

    // MARK: Models

    @Test("reason codes map to messages and unknown ones fall back to a generic one")
    func decisionReasons() {
        #expect(PlaceSuggestionDecisionReason(code: "duplicate") == .duplicate)
        #expect(PlaceSuggestionDecisionReason(code: "outside_area") == .outsideArea)
        #expect(PlaceSuggestionDecisionReason(code: "type_not_accepted") == .typeNotAccepted)
        #expect(PlaceSuggestionDecisionReason(code: "accepted_manual") == .acceptedManual)
        #expect(PlaceSuggestionDecisionReason(code: "low_trust") == .other("low_trust"))
        #expect(PlaceSuggestionDecisionReason.other("x").messageKey == "placeSuggestion.decisionReason.other")
    }

    @Test("every reason message exists in both languages")
    func reasonMessagesAreLocalized() {
        let reasons: [PlaceSuggestionDecisionReason] = [
            .duplicate, .outsideArea, .typeNotAccepted, .notARealPlace, .inappropriate, .acceptedManual, .other("x")
        ]
        for reason in reasons {
            #expect(L10n.string(reason.messageKey) != reason.messageKey)
        }
    }

    @Test("only pending and needs_review count as under review")
    func underReview() {
        #expect(PlaceSuggestionStatus.pending.isUnderReview)
        #expect(PlaceSuggestionStatus.needsReview.isUnderReview)
        #expect(!PlaceSuggestionStatus.approved.isUnderReview)
        #expect(!PlaceSuggestionStatus.rejected.isUnderReview)
    }

    // MARK: My suggestions

    @Test("my suggestions loads the list, and a failure explains itself")
    func mySuggestions() async {
        let service = MockPlaceSuggestionService()
        service.fetchMineResult = .success([PlaceSuggestionViewModelTests.suggestion(status: .approved, name: "A")])
        let viewModel = MySuggestionsViewModel(service: service)

        await viewModel.load()

        #expect(viewModel.suggestions.count == 1)
        #expect(viewModel.hasLoaded)
        #expect(viewModel.errorMessage == nil)

        service.fetchMineResult = .failure(APIError.httpStatus(500, message: nil))
        await viewModel.load()

        #expect(viewModel.errorMessage == L10n.string("placeSuggestion.mySuggestions.error.message"))
        #expect(viewModel.suggestions.count == 1)
    }

    // MARK: Status notice

    private func suggestion(
        _ id: String,
        _ status: PlaceSuggestionStatus,
        created: Date,
        decided: Date? = nil
    ) -> MySuggestion {
        MySuggestion(
            id: id, status: status, name: "N", address: "A", note: nil, decisionReason: nil,
            placeID: nil, createdAt: created, decidedAt: decided
        )
    }

    private func makeNotice(
        _ service: MockPlaceSuggestionService,
        store: InMemoryPlaceSuggestionStatusStore,
        clock: TestClock
    ) -> SuggestionStatusNoticeViewModel {
        SuggestionStatusNoticeViewModel(service: service, store: store, now: { clock.date })
    }

    @Test("the first check only records what is there")
    func noticeFirstRunIsSilent() async {
        let service = MockPlaceSuggestionService()
        service.fetchMineResult = .success([suggestion("a", .approved, created: Date(timeIntervalSince1970: 0))])
        let store = InMemoryPlaceSuggestionStatusStore()
        let notice = makeNotice(service, store: store, clock: TestClock(Date(timeIntervalSince1970: 100)))

        #expect(await notice.checkForChanges() == nil)
        #expect(store.lastSeenStatuses() == ["a": "approved"])
    }

    @Test("a suggestion that was in review and got decided is told once")
    func noticeTellsDecisionOnce() async {
        let service = MockPlaceSuggestionService()
        let clock = TestClock(Date(timeIntervalSince1970: 100))
        let store = InMemoryPlaceSuggestionStatusStore()
        let created = Date(timeIntervalSince1970: 0)
        service.fetchMineResult = .success([suggestion("a", .needsReview, created: created)])
        let notice = makeNotice(service, store: store, clock: clock)
        _ = await notice.checkForChanges()

        clock.advance(by: 1_000)
        service.fetchMineResult = .success([suggestion("a", .approved, created: created, decided: clock.date)])

        #expect(await notice.checkForChanges() == L10n.string("placeSuggestion.notice.added", 1))
        #expect(await notice.checkForChanges() == nil)
    }

    @Test("a refusal and an addition together are told as one message")
    func noticeMixed() async {
        let service = MockPlaceSuggestionService()
        let clock = TestClock(Date(timeIntervalSince1970: 100))
        let store = InMemoryPlaceSuggestionStatusStore()
        let created = Date(timeIntervalSince1970: 0)
        service.fetchMineResult = .success([
            suggestion("a", .needsReview, created: created), suggestion("b", .needsReview, created: created)
        ])
        let notice = makeNotice(service, store: store, clock: clock)
        _ = await notice.checkForChanges()

        clock.advance(by: 1_000)
        service.fetchMineResult = .success([
            suggestion("a", .approved, created: created, decided: clock.date),
            suggestion("b", .rejected, created: created, decided: clock.date)
        ])

        #expect(await notice.checkForChanges() == L10n.string("placeSuggestion.notice.mixed", 1, 1))
    }

    @Test("a decision made while the request was answered is not told again")
    func noticeSkipsInstantDecisions() async {
        let service = MockPlaceSuggestionService()
        let clock = TestClock(Date(timeIntervalSince1970: 100))
        let store = InMemoryPlaceSuggestionStatusStore()
        let notice = makeNotice(service, store: store, clock: clock)
        service.fetchMineResult = .success([])
        _ = await notice.checkForChanges()

        clock.advance(by: 1_000)
        service.fetchMineResult = .success([suggestion("a", .approved, created: clock.date, decided: clock.date)])

        #expect(await notice.checkForChanges() == nil)
    }

    @Test("a suggestion sent and decided by a person since the last look is told")
    func noticeTellsSlowDecisionNeverSeen() async {
        let service = MockPlaceSuggestionService()
        let clock = TestClock(Date(timeIntervalSince1970: 100))
        let store = InMemoryPlaceSuggestionStatusStore()
        let notice = makeNotice(service, store: store, clock: clock)
        service.fetchMineResult = .success([])
        _ = await notice.checkForChanges()

        let created = clock.date.addingTimeInterval(10)
        clock.advance(by: 1_000)
        service.fetchMineResult = .success([suggestion("a", .rejected, created: created, decided: clock.date)])

        #expect(await notice.checkForChanges() == L10n.string("placeSuggestion.notice.notApproved", 1))
    }

    @Test("a failed fetch tells nothing and keeps what was recorded")
    func noticeFailure() async {
        let service = MockPlaceSuggestionService()
        service.fetchMineResult = .failure(APIError.httpStatus(500, message: nil))
        let store = InMemoryPlaceSuggestionStatusStore()
        let notice = makeNotice(service, store: store, clock: TestClock())

        #expect(await notice.checkForChanges() == nil)
        #expect(store.lastCheckedAt() == nil)
    }
}

final class InMemoryPlaceSuggestionStatusStore: PlaceSuggestionStatusStoring {
    private var statuses: [String: String] = [:]
    private var checkedAt: Date?

    func lastSeenStatuses() -> [String: String] { statuses }
    func lastCheckedAt() -> Date? { checkedAt }
    func save(_ statuses: [String: String], checkedAt: Date) {
        self.statuses = statuses
        self.checkedAt = checkedAt
    }
}

private final class CapturingNetworkClient: NetworkClient, @unchecked Sendable {
    private let json: String
    private(set) var lastGetPath: String?
    private(set) var lastQueryItems: [URLQueryItem] = []
    private(set) var lastSendPath: String?
    private(set) var lastSendMethod: HTTPMethod?
    private(set) var lastBody: Data?

    init(json: String) {
        self.json = json
    }

    var lastBodyJSON: [String: Any]? {
        guard let lastBody else { return nil }
        return (try? JSONSerialization.jsonObject(with: lastBody)) as? [String: Any]
    }

    func get<Response: Decodable>(path: String, queryItems: [URLQueryItem]) async throws -> Response {
        lastGetPath = path
        lastQueryItems = queryItems
        return try JSONDecoder().decode(Response.self, from: Data(json.utf8))
    }

    func send<Body: Encodable, Response: Decodable>(
        path: String,
        method: HTTPMethod,
        body: Body
    ) async throws -> Response {
        lastSendPath = path
        lastSendMethod = method
        lastBody = try JSONEncoder().encode(body)
        return try JSONDecoder().decode(Response.self, from: Data(json.utf8))
    }

    func sendWithoutResponse(path: String, method: HTTPMethod) async throws {}
}
