import Foundation
import Testing
@testable import ZanzarProject

@MainActor
@Suite("ItineraryService")
struct ItineraryServiceTests {
    private static let fixedDetailJSON = """
    {
      "slug": "centro-historico",
      "name": "Centro Histórico",
      "description": "Um passeio pelos marcos históricos.",
      "category": "historic",
      "routeType": "fixed",
      "objectives": ["História", "Arquitetura"],
      "placesCount": 2,
      "completedCount": 42,
      "coverImageUrl": "https://example.com/cover.jpg",
      "places": [
        {
          "placeId": "ChIJ1",
          "name": "Paço da Liberdade",
          "location": { "lat": -25.4284, "lng": -49.2733 }
        },
        {
          "placeId": "ChIJ2",
          "name": "Museu Paranaense",
          "location": { "lat": -25.4290, "lng": -49.2720 }
        }
      ]
    }
    """

    private static let freeDetailJSON = """
    {
      "slug": "visitando-parques",
      "name": "Visitando Parques",
      "description": "Conheça parques da cidade.",
      "category": "park",
      "routeType": "free",
      "objectives": ["Natureza"],
      "targetCategory": "park",
      "targetCount": 3,
      "placesCount": 3,
      "completedCount": 10,
      "places": []
    }
    """

    private static let activeFixedJSON = """
    {
      "itineraryTemplateId": "674abc123def456789012345",
      "slug": "centro-historico",
      "name": "Centro Histórico",
      "description": "Um passeio pelos marcos históricos.",
      "category": "historic",
      "routeType": "fixed",
      "objectives": ["História"],
      "startedAt": "2026-10-06T12:00:00.000Z",
      "places": [
        {
          "placeId": "ChIJ1",
          "placeName": "Paço da Liberdade",
          "isCompleted": true,
          "datetime": "2026-10-06T13:00:00Z",
          "stamp": "stamp_historic"
        },
        {
          "placeId": "ChIJ2",
          "placeName": "Museu Paranaense",
          "isCompleted": false
        }
      ]
    }
    """

    private static let activeFreeJSON = """
    {
      "itineraryTemplateId": "674abc123def456789012346",
      "slug": "visitando-parques",
      "name": "Visitando Parques",
      "description": "Conheça parques da cidade.",
      "category": "park",
      "routeType": "free",
      "objectives": ["Natureza"],
      "targetCategory": "park",
      "targetCount": 3,
      "startedAt": "2026-10-06T12:00:00Z",
      "places": [
        { "isCompleted": true, "placeId": "ChIJ9", "placeName": "Parque Barigui" },
        { "isCompleted": false },
        { "isCompleted": false }
      ]
    }
    """

    private static let listJSON = """
    [
      {
        "slug": "centro-historico",
        "name": "Centro Histórico",
        "category": "historic",
        "routeType": "fixed",
        "placesCount": 2,
        "completedCount": 42,
        "coverImageUrl": "https://example.com/cover.jpg"
      },
      {
        "slug": "visitando-parques",
        "name": "Visitando Parques",
        "category": "park",
        "routeType": "free",
        "placesCount": 3,
        "completedCount": 10
      }
    ]
    """

    // MARK: - Decoding

    @Test("maps a fixed-route itinerary detail")
    func mapsFixedDetail() throws {
        let detail = try Self.decodeDetail(Self.fixedDetailJSON)

        #expect(detail.slug == "centro-historico")
        #expect(detail.routeType == .fixed)
        #expect(detail.targetCategory == nil)
        #expect(detail.targetCount == nil)
        #expect(detail.places.count == 2)
        #expect(detail.places[0].placeID == "ChIJ1")
        #expect(detail.places[0].latitude == -25.4284)
    }

    @Test("maps a free-route itinerary detail")
    func mapsFreeDetail() throws {
        let detail = try Self.decodeDetail(Self.freeDetailJSON)

        #expect(detail.slug == "visitando-parques")
        #expect(detail.routeType == .free)
        #expect(detail.targetCategory == .park)
        #expect(detail.targetCount == 3)
        #expect(detail.places.isEmpty)
    }

    @Test("maps an active fixed-route itinerary with slots")
    func mapsActiveFixed() throws {
        let active = try Self.decodeActive(Self.activeFixedJSON)

        #expect(active.slug == "centro-historico")
        #expect(active.routeType == .fixed)
        #expect(active.places.count == 2)
        #expect(active.places[0].isCompleted)
        #expect(active.places[0].stampID == "stamp_historic")
        #expect(active.places[1].isCompleted == false)
        #expect(active.startedAt == Date(timeIntervalSince1970: 1_790_251_200))
    }

    @Test("maps an active free-route itinerary with anonymous slots")
    func mapsActiveFree() throws {
        let active = try Self.decodeActive(Self.activeFreeJSON)

        #expect(active.routeType == .free)
        #expect(active.targetCategory == .park)
        #expect(active.targetCount == 3)
        #expect(active.places.count == 3)
        #expect(active.places[0].placeID == "ChIJ9")
        #expect(active.places[1].id == "slot-1")
    }

    @Test("maps itinerary list items")
    func mapsList() throws {
        let items = try Self.decodeList(Self.listJSON)

        #expect(items.count == 2)
        #expect(items[0].slug == "centro-historico")
        #expect(items[0].placesCount == 2)
        #expect(items[1].routeType == .free)
    }

    // MARK: - Requests

    @Test("fetchItineraries requests GET /itineraries")
    func fetchItinerariesRequest() async throws {
        let client = ItineraryStubNetworkClient(responseJSON: Self.listJSON)
        let service = ItineraryService(client: client)

        let items = try await service.fetchItineraries()

        #expect(client.lastGetPath == "itineraries")
        #expect(items.count == 2)
    }

    @Test("fetchItineraryDetail requests GET /itineraries/{slug}")
    func fetchDetailRequest() async throws {
        let client = ItineraryStubNetworkClient(responseJSON: Self.fixedDetailJSON)
        let service = ItineraryService(client: client)

        let detail = try await service.fetchItineraryDetail(slug: "centro-historico")

        #expect(client.lastGetPath == "itineraries/centro-historico")
        #expect(detail.places.count == 2)
    }

    @Test("fetchItineraryDetail rejects malformed slugs")
    func fetchDetailRejectsMalformedSlug() async {
        let client = ItineraryStubNetworkClient(responseJSON: Self.fixedDetailJSON)
        let service = ItineraryService(client: client)

        await #expect(throws: APIError.self) {
            try await service.fetchItineraryDetail(slug: "../logout")
        }
        #expect(client.lastGetPath == nil)
    }

    @Test("activateItinerary posts to /itineraries/{slug}/activate")
    func activateRequest() async throws {
        let client = ItineraryStubNetworkClient(responseJSON: Self.activeFixedJSON)
        let service = ItineraryService(client: client)

        let active = try await service.activateItinerary(slug: "centro-historico")

        #expect(client.lastSendPath == "itineraries/centro-historico/activate")
        #expect(client.lastSendMethod == .post)
        #expect(active.slug == "centro-historico")
    }

    @Test("abandonActiveItinerary posts to /itineraries/active/abandon")
    func abandonRequest() async throws {
        let client = ItineraryStubNetworkClient(responseJSON: "{}")
        let service = ItineraryService(client: client)

        try await service.abandonActiveItinerary()

        #expect(client.lastEmptyPath == "itineraries/active/abandon")
        #expect(client.lastEmptyMethod == .post)
    }

    @Test("fetchActiveItinerary returns nil when the backend sends null")
    func fetchActiveNil() async throws {
        let client = ItineraryStubNetworkClient(responseJSON: "null")
        let service = ItineraryService(client: client)

        let active = try await service.fetchActiveItinerary(userID: "user-1")

        #expect(client.lastGetPath == "user/user-1/itinerary")
        #expect(active == nil)
    }

    @Test("fetchActiveItinerary maps an active payload")
    func fetchActivePayload() async throws {
        let client = ItineraryStubNetworkClient(responseJSON: Self.activeFreeJSON)
        let service = ItineraryService(client: client)

        let active = try await service.fetchActiveItinerary(userID: "user-1")

        #expect(active?.routeType == .free)
        #expect(active?.places.count == 3)
    }

    private static func decodeDetail(_ json: String) throws -> ItineraryDetail {
        try JSONDecoder().decode(ItineraryDetailAPIResponse.self, from: Data(json.utf8)).makeItineraryDetail()
    }

    private static func decodeActive(_ json: String) throws -> ActiveItinerary {
        try JSONDecoder().decode(ActiveItineraryAPIResponse.self, from: Data(json.utf8)).makeActiveItinerary()
    }

    private static func decodeList(_ json: String) throws -> [Itinerary] {
        try JSONDecoder().decode([ItineraryListItemAPIResponse].self, from: Data(json.utf8)).map { $0.makeItinerary() }
    }
}

private final class ItineraryStubNetworkClient: NetworkClient, @unchecked Sendable {
    private let responseJSON: String
    var emptyError: Error?

    private(set) var lastGetPath: String?
    private(set) var lastQueryItems: [URLQueryItem]?
    private(set) var lastSendPath: String?
    private(set) var lastSendMethod: HTTPMethod?
    private(set) var lastEmptyPath: String?
    private(set) var lastEmptyMethod: HTTPMethod?

    init(responseJSON: String) {
        self.responseJSON = responseJSON
    }

    func get<Response: Decodable>(path: String, queryItems: [URLQueryItem]) async throws -> Response {
        lastGetPath = path
        lastQueryItems = queryItems
        return try JSONDecoder().decode(Response.self, from: Data(responseJSON.utf8))
    }

    func send<Body: Encodable, Response: Decodable>(path: String, method: HTTPMethod, body: Body) async throws -> Response {
        lastSendPath = path
        lastSendMethod = method
        return try JSONDecoder().decode(Response.self, from: Data(responseJSON.utf8))
    }

    func sendWithoutResponse(path: String, method: HTTPMethod) async throws {
        lastEmptyPath = path
        lastEmptyMethod = method
        if let emptyError { throw emptyError }
    }
}
