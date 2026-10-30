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
      "images": [{ "url": "https://img.example/a.jpg", "credit": { "author": "Ana", "license": "CC BY 4.0", "sourceUrl": "https://commons.example/File:A.jpg" } }],
      "zanzar": { "category": "bar", "checkInCount": 2, "impressionCounts": { "happy": 1 } },
      "distanceMeters": 50,
      "userContext": { "hasCheckedIn": false, "isInActiveItinerary": false }
    }
    """

    private static func placeJSON(images: [String]) -> String {
        let photos = images.joined(separator: ", ")
        return """
        {
          "place_id": "ChIJ1",
          "name": "Bar do Zé",
          "geometry": { "location": { "lat": -25.43, "lng": -49.27 } },
          "images": [\(photos)],
          "zanzar": { "category": "bar", "checkInCount": 2, "impressionCounts": { "happy": 1 } },
          "distanceMeters": 50,
          "userContext": { "hasCheckedIn": false, "isInActiveItinerary": false }
        }
        """
    }

    private static func imageJSON(url: String) -> String {
        #"{ "url": "\#(url)", "credit": { "author": "Ana", "license": "CC BY 4.0", "sourceUrl": "https://commons.example/File:A.jpg" } }"#
    }

    private func fetchDetail(placeJSON: String) async throws -> PlaceDetail {
        let client = PathAwareNetworkClient(
            responsesByPathPrefix: [
                "places/ChIJ1": placeJSON,
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
            userID: "user-1",
            nearbyPlaces: []
        )
        return try await service.fetchPlaceDetail(context: context)
    }

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
            userID: "user-1",
            nearbyPlaces: []
        )

        let detail = try await service.fetchPlaceDetail(context: context)

        #expect(detail.id == "ChIJ1")
        #expect(detail.photos.map(\.url) == [URL(string: "https://img.example/a.jpg")!])
        #expect(detail.photos.first?.credit == PhotoCredit(
            author: "Ana",
            license: "CC BY 4.0",
            sourceURL: URL(string: "https://commons.example/File:A.jpg")!
        ))
        #expect(detail.category == .bar)
    }

    @Test("fetchPlaceDetail keeps the first five photos in the order the backend sends them")
    func photosAreCappedAtFive() async throws {
        let images = (1...8).map { Self.imageJSON(url: "https://img.example/\($0).jpg") }
        let detail = try await fetchDetail(placeJSON: Self.placeJSON(images: images))

        #expect(detail.photos.map(\.url.lastPathComponent) == ["1.jpg", "2.jpg", "3.jpg", "4.jpg", "5.jpg"])
    }

    @Test("fetchPlaceDetail keeps every photo when there are fewer than the cap")
    func fewPhotosAreAllKept() async throws {
        let images = ["a", "b"].map { Self.imageJSON(url: "https://img.example/\($0).jpg") }
        let detail = try await fetchDetail(placeJSON: Self.placeJSON(images: images))

        #expect(detail.photos.map(\.url.lastPathComponent) == ["a.jpg", "b.jpg"])
    }

    @Test("fetchPlaceDetail maps a place without photos to an empty list")
    func noPhotos() async throws {
        let detail = try await fetchDetail(placeJSON: Self.placeJSON(images: []))

        #expect(detail.photos.isEmpty)
    }

    @Test("fetchPlaceDetail skips an http image and an image that cannot be decoded, and keeps the rest")
    func malformedImagesAreSkipped() async throws {
        let images = [
            Self.imageJSON(url: "http://img.example/insecure.jpg"),
            #"{ "credit": { "author": "Ana" } }"#,
            Self.imageJSON(url: "https://img.example/ok.jpg")
        ]
        let detail = try await fetchDetail(placeJSON: Self.placeJSON(images: images))

        #expect(detail.photos.map(\.url.lastPathComponent) == ["ok.jpg"])
    }

    @Test("fetchPlaceDetail keeps an image whose credit is unusable, without a credit")
    func imageWithoutUsableCredit() async throws {
        let withoutCredit = #"{ "url": "https://img.example/a.jpg" }"#
        let badSource = #"{ "url": "https://img.example/b.jpg", "credit": { "author": "Ana", "license": "CC0", "sourceUrl": "http://insecure.example" } }"#
        let detail = try await fetchDetail(placeJSON: Self.placeJSON(images: [withoutCredit, badSource]))

        #expect(detail.photos.map(\.url.lastPathComponent) == ["a.jpg", "b.jpg"])
        #expect(detail.photos.allSatisfy { $0.credit == nil })
    }

    @Test("fetchPlaceDetail maps a payload that still has no images field to no photos")
    func missingImagesField() async throws {
        let json = #"{ "place_id": "ChIJ1", "name": "Bar", "geometry": { "location": { "lat": 1, "lng": 2 } }, "zanzar": { "category": "bar" } }"#
        let detail = try await fetchDetail(placeJSON: json)

        #expect(detail.photos.isEmpty)
    }

    @Test("fetchPlaceDetail picks nearby places from the context instead of asking the server")
    func nearbyPlacesComeFromContext() async throws {
        let client = PathAwareNetworkClient(responsesByPathPrefix: ["places/ChIJ1": Self.placeJSON])
        let service = PlaceDetailService(client: client)
        let place = MapPlace(
            id: "ChIJ1",
            name: "Bar do Zé",
            latitude: -25.43,
            longitude: -49.27,
            category: .bar,
            distanceMeters: 50
        )
        let neighbour = MapPlace(
            id: "ChIJ2",
            name: "Parque",
            latitude: -25.44,
            longitude: -49.28,
            category: .park,
            distanceMeters: 300
        )
        let context = PlaceDetailLoadContext(
            place: place,
            userCoordinate: UserCoordinate(latitude: -25.43, longitude: -49.27),
            userID: "user-1",
            nearbyPlaces: [place, neighbour]
        )

        let detail = try await service.fetchPlaceDetail(context: context)

        #expect(detail.nearbyPlaces.map(\.id) == ["ChIJ2"])
        #expect(!client.getPaths.contains("places"))
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
    private(set) var getPaths: [String] = []

    init(responsesByPathPrefix: [String: String], sendResponseJSON: String? = nil) {
        self.responsesByPathPrefix = responsesByPathPrefix
        self.sendResponseJSON = sendResponseJSON
    }

    func get<Response: Decodable>(path: String, queryItems: [URLQueryItem]) async throws -> Response {
        getPaths.append(path)
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
