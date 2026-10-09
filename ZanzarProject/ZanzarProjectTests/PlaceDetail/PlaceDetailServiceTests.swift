import Foundation
import Testing
@testable import ZanzarProject

@MainActor
@Suite("PlaceDetailService")
struct PlaceDetailServiceTests {
    private static let placeJSON = """
    {
      "place_id": "ChIJ1",
      "name": "Bar do Zé",
      "geometry": { "location": { "lat": -25.43, "lng": -49.27 } },
      "photos": [{ "photo_reference": "AUacSh", "height": 100, "width": 100 }],
      "zanzar": { "category": "bar", "checkInCount": 2, "impressionCounts": { "happy": 1 } },
      "distanceMeters": 50,
      "userContext": { "hasCheckedIn": false, "isInActiveItinerary": false }
    }
    """

    @Test("fetchPlaceDetail maps the backend payload")
    func fetchPlaceDetail() async throws {
        let client = PathAwareNetworkClient(
            responsesByPathPrefix: [
                "places/ChIJ1": Self.placeJSON,
                "checkIn": #"{"placeId":"ChIJ1"}"#,
                "rating": #"{"impressionTag":"happy"}"#,
                "places": "[]"
            ]
        )
        let service = PlaceDetailService(client: client)
        let context = PlaceDetailLoadContext(
            place: MapPlace(
                id: "ChIJ1",
                name: "Bar do Zé",
                latitude: -25.43,
                longitude: -49.27,
                category: .bar,
                distanceMeters: 50,
                pinStyle: .available
            ),
            userCoordinate: UserCoordinate(latitude: -25.43, longitude: -49.27),
            userID: "user-1"
        )

        let detail = try await service.fetchPlaceDetail(context: context)

        #expect(detail.id == "ChIJ1")
        #expect(detail.heroPhotoReference == "AUacSh")
        #expect(detail.category == .bar)
    }

    @Test("checkIn decodes the synchronous payload")
    func checkIn() async throws {
        let checkInJSON = """
        {
          "stampIdGranted": "stamp_bar",
          "isNewStamp": true,
          "itineraryProgress": { "completedSlots": 1, "totalSlots": 4 },
          "isItineraryCompleted": false
        }
        """
        let client = PathAwareNetworkClient(responsesByPathPrefix: [:], sendResponseJSON: checkInJSON)
        let service = PlaceDetailService(client: client)

        let coordinate = UserCoordinate(latitude: -25.43, longitude: -49.27, accuracyMeters: 8)
        let result = try await service.checkIn(placeID: "ChIJ1", coordinate: coordinate)

        #expect(result.isNewStamp)
        #expect(result.sealCategory == .bar)
        #expect(client.lastSendPath == "checkIn")
        let body = try JSONDecoder().decode(SentCheckInBody.self, from: try #require(client.lastSendBody))
        #expect(body.coordinates.lat == coordinate.latitude)
        #expect(body.coordinates.lng == coordinate.longitude)
        #expect(body.coordinates.accuracyMeters == 8)
    }
}

private struct SentCheckInBody: Decodable {
    struct Coordinates: Decodable {
        let lat: Double
        let lng: Double
        let accuracyMeters: Double?
    }

    let coordinates: Coordinates
}

private final class PathAwareNetworkClient: NetworkClient, @unchecked Sendable {
    private let responsesByPathPrefix: [String: String]
    private let sendResponseJSON: String?
    private(set) var lastSendPath: String?
    private(set) var lastSendBody: Data?

    init(responsesByPathPrefix: [String: String], sendResponseJSON: String? = nil) {
        self.responsesByPathPrefix = responsesByPathPrefix
        self.sendResponseJSON = sendResponseJSON
    }

    func get<Response: Decodable>(path: String, queryItems: [URLQueryItem]) async throws -> Response {
        if path.hasPrefix("checkIn") || path == "checkIn" {
            throw APIError.httpStatus(404, message: nil)
        }
        if path.hasPrefix("rating") || path == "rating" {
            throw APIError.httpStatus(404, message: nil)
        }

        let matchingKey = responsesByPathPrefix.keys
            .filter { path.hasPrefix($0) || path == $0 }
            .max(by: { $0.count < $1.count })
        let json = matchingKey.flatMap { responsesByPathPrefix[$0] } ?? "[]"
        return try JSONDecoder().decode(Response.self, from: Data(json.utf8))
    }

    func send<Body: Encodable, Response: Decodable>(
        path: String,
        method: HTTPMethod,
        body: Body
    ) async throws -> Response {
        lastSendPath = path
        lastSendBody = try JSONEncoder().encode(body)
        let json = sendResponseJSON ?? "{}"
        return try JSONDecoder().decode(Response.self, from: Data(json.utf8))
    }

    func sendWithoutResponse(path: String, method: HTTPMethod) async throws {}
}
