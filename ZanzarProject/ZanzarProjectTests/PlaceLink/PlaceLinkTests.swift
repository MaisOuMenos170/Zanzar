import Foundation
import Testing
@testable import ZanzarProject

@MainActor
@Suite("PlaceLink")
struct PlaceLinkTests {
    private let baseURL = URL(string: "https://api.example.app")!

    @Test("the shared link is the API host's /p/<id> page")
    func buildsSharedLink() {
        let url = PlaceLink.url(for: "ChIJabc-123", baseURL: baseURL)

        #expect(url.absoluteString == "https://api.example.app/p/ChIJabc-123")
    }

    @Test("reads the place of a link the app shared, and of the scheme the web page opens")
    func readsPlaceLinks() throws {
        let shared = try #require(URL(string: "https://api.example.app/p/ChIJabc-123"))
        let scheme = try #require(URL(string: "lero://place/ChIJabc-123"))

        #expect(PlaceLink.placeID(from: shared, baseURL: baseURL) == "ChIJabc-123")
        #expect(PlaceLink.placeID(from: scheme, baseURL: baseURL) == "ChIJabc-123")
    }

    @Test("a link built for a place reads back as that place")
    func roundTrips() {
        let url = PlaceLink.url(for: "ChIJ_x-9", baseURL: baseURL)

        #expect(PlaceLink.placeID(from: url, baseURL: baseURL) == "ChIJ_x-9")
    }

    @Test("ignores links that are not for a place of this app", arguments: [
        "https://other.example.app/p/ChIJabc",
        "https://api.example.app/reset-password?token=abc",
        "https://api.example.app/p",
        "https://api.example.app/p/a/b",
        "lero://reset-password?token=abc",
        "lero://place",
        "mailto:someone@example.com"
    ])
    func ignoresOtherLinks(link: String) throws {
        let url = try #require(URL(string: link))

        #expect(PlaceLink.placeID(from: url, baseURL: baseURL) == nil)
    }
}

@MainActor
@Suite("PlaceLinkService")
struct PlaceLinkServiceTests {
    @Test("finds the place of a link from its detail")
    func resolvesPlace() async throws {
        let json = """
        {
          "place_id": "ChIJ1",
          "name": "Jardim Botânico",
          "geometry": { "location": { "lat": -25.44, "lng": -49.24 } },
          "images": [],
          "zanzar": { "category": "park", "checkInCount": 3, "impressionCounts": {} }
        }
        """
        let client = StubNetworkClient(responseJSON: json)
        let service = PlaceLinkService(client: client)

        let place = try await service.place(id: "ChIJ1")

        #expect(client.lastGetPath == "places/ChIJ1")
        #expect(place.id == "ChIJ1")
        #expect(place.name == "Jardim Botânico")
        #expect(place.category == .park)
        #expect(place.latitude == -25.44)
    }
}

private final class StubNetworkClient: NetworkClient, @unchecked Sendable {
    private let responseJSON: String
    private(set) var lastGetPath: String?

    init(responseJSON: String) {
        self.responseJSON = responseJSON
    }

    func get<Response: Decodable>(path: String, queryItems: [URLQueryItem]) async throws -> Response {
        lastGetPath = path
        return try JSONDecoder().decode(Response.self, from: Data(responseJSON.utf8))
    }

    func send<Body: Encodable, Response: Decodable>(
        path: String,
        method: HTTPMethod,
        body: Body
    ) async throws -> Response {
        try JSONDecoder().decode(Response.self, from: Data(responseJSON.utf8))
    }

    func sendWithoutResponse(path: String, method: HTTPMethod) async throws {}
}
