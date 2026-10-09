import Foundation
import Testing
@testable import ZanzarProject

@MainActor
@Suite("LocationMapService")
struct LocationMapServiceTests {
    @Test("fetchNearbyPlaces requests coordinates and maps responses")
    func fetchNearbyPlaces() async throws {
        let json = """
        [{
          "place_id": "ChIJ1",
          "name": "Parque",
          "geometry": { "location": { "lat": -25.43, "lng": -49.27 } },
          "zanzar": { "category": "park" },
          "distanceMeters": 120
        }]
        """
        let client = StubNetworkClient(responseJSON: json)
        let service = LocationMapService(client: client)
        let coordinate = UserCoordinate(latitude: -25.43, longitude: -49.27)

        let places = try await service.fetchNearbyPlaces(from: coordinate)

        #expect(places.count == 1)
        #expect(places[0].id == "ChIJ1")
        #expect(places[0].category == .park)
        #expect(client.lastGetPath == "places")
        #expect(client.lastQueryItems?.contains(URLQueryItem(name: "lat", value: "-25.43")) == true)
    }
}

private final class StubNetworkClient: NetworkClient, @unchecked Sendable {
    private let responseJSON: String
    private(set) var lastGetPath: String?
    private(set) var lastQueryItems: [URLQueryItem]?

    init(responseJSON: String) {
        self.responseJSON = responseJSON
    }

    func get<Response: Decodable>(path: String, queryItems: [URLQueryItem]) async throws -> Response {
        lastGetPath = path
        lastQueryItems = queryItems
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
