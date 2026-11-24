import Foundation
import Testing
@testable import ZanzarProject

@MainActor
@Suite("PlaceSearchService")
struct PlaceSearchServiceTests {
    private static let json = """
    [{
      "place_id": "ChIJ1",
      "name": "Café do Mercado",
      "geometry": { "location": { "lat": -25.43, "lng": -49.27 } },
      "zanzar": { "category": "cafe" },
      "distanceMeters": 120,
      "userContext": { "hasCheckedIn": true, "isInActiveItinerary": true }
    }]
    """

    @Test("Requests /places/search with the text and the position, and maps the places")
    func request() async throws {
        let client = StubSearchClient(responseJSON: Self.json)
        let service = PlaceSearchService(client: client)
        let coordinate = UserCoordinate(latitude: -25.43, longitude: -49.27)

        let places = try await service.searchPlaces(query: "caf", near: coordinate, categories: [])

        #expect(client.lastPath == "places/search")
        #expect(client.lastQueryItems.contains(URLQueryItem(name: "q", value: "caf")))
        #expect(client.lastQueryItems.contains(URLQueryItem(name: "lat", value: "-25.43")))
        #expect(client.lastQueryItems.contains(URLQueryItem(name: "lng", value: "-49.27")))
        #expect(!client.lastQueryItems.contains { $0.name == "categories" })
        #expect(places.map(\.id) == ["ChIJ1"])
        #expect(places[0].category == .cafe)
        #expect(places[0].pinStyle == .checkedIn)
        #expect(places[0].isInActiveItinerary)
    }

    @Test("Sends the chosen types as a sorted, comma-separated list")
    func categories() async throws {
        let client = StubSearchClient(responseJSON: "[]")
        let service = PlaceSearchService(client: client)

        _ = try await service.searchPlaces(
            query: "ba",
            near: UserCoordinate(latitude: 0, longitude: 0),
            categories: [.cafe, .bar, .park]
        )

        #expect(client.lastQueryItems.contains(URLQueryItem(name: "categories", value: "bar,cafe,park")))
    }
}

private final class StubSearchClient: NetworkClient, @unchecked Sendable {
    private let responseJSON: String
    private(set) var lastPath: String?
    private(set) var lastQueryItems: [URLQueryItem] = []

    init(responseJSON: String) {
        self.responseJSON = responseJSON
    }

    func get<Response: Decodable>(path: String, queryItems: [URLQueryItem]) async throws -> Response {
        lastPath = path
        lastQueryItems = queryItems
        return try JSONDecoder().decode(Response.self, from: Data(responseJSON.utf8))
    }

    func send<Body: Encodable, Response: Decodable>(
        path: String,
        method: HTTPMethod,
        body: Body
    ) async throws -> Response {
        throw URLError(.unsupportedURL)
    }

    func sendWithoutResponse(path: String, method: HTTPMethod) async throws {
        throw URLError(.unsupportedURL)
    }
}
