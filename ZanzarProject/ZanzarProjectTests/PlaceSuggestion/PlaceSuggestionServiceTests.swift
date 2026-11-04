import CoreLocation
import Foundation
import Testing
@testable import ZanzarProject

@MainActor
@Suite("PlaceSuggestionService")
struct PlaceSuggestionServiceTests {
    private static let createdJSON = """
    {
      "_id": "665f1c2e8a1b2c3d4e5f6a7b",
      "userId": "665f1c2e8a1b2c3d4e5f0000",
      "coordinates": { "latitude": -25.43, "longitude": -49.27 },
      "address": "Rua XV de Novembro, 1200",
      "note": "Vale a pena",
      "createdAt": "2026-11-04T12:00:00.000Z",
      "__v": 0
    }
    """

    private static let curitiba = SuggestedLocation(
        latitude: -25.43,
        longitude: -49.27,
        address: "Rua XV de Novembro, 1200"
    )

    private func makeService(
        client: PlaceSuggestionStubNetworkClient? = nil,
        locationService: PlaceSuggestionStubLocationService = PlaceSuggestionStubLocationService(),
        geocoder: PlaceSuggestionStubGeocoder = PlaceSuggestionStubGeocoder()
    ) -> PlaceSuggestionService {
        PlaceSuggestionService(
            client: client ?? PlaceSuggestionStubNetworkClient(responseJSON: Self.createdJSON),
            locationService: locationService,
            geocoder: geocoder
        )
    }

    @Test("submit posts the coordinates, address and note to place-suggestions")
    func submitSendsExpectedRequest() async throws {
        let client = PlaceSuggestionStubNetworkClient(responseJSON: Self.createdJSON)
        let service = makeService(client: client)

        try await service.submit(PlaceSuggestion(location: Self.curitiba, note: "Vale a pena"))

        #expect(client.lastSendPath == "place-suggestions")
        #expect(client.lastSendMethod == .post)
        let body = try #require(client.lastBodyJSON)
        #expect(body["address"] as? String == "Rua XV de Novembro, 1200")
        #expect(body["note"] as? String == "Vale a pena")
        let coordinates = try #require(body["coordinates"] as? [String: Double])
        #expect(coordinates["latitude"] == -25.43)
        #expect(coordinates["longitude"] == -49.27)
        #expect(body["userId"] == nil)
    }

    @Test("submit trims the note and leaves it out when it is blank")
    func submitOmitsBlankNote() async throws {
        let client = PlaceSuggestionStubNetworkClient(responseJSON: Self.createdJSON)
        let service = makeService(client: client)

        try await service.submit(PlaceSuggestion(location: Self.curitiba, note: "   \n "))

        let body = try #require(client.lastBodyJSON)
        #expect(body["note"] == nil)
    }

    @Test("submit cuts an address longer than the backend limit")
    func submitTruncatesAddress() async throws {
        let client = PlaceSuggestionStubNetworkClient(responseJSON: Self.createdJSON)
        let service = makeService(client: client)
        let longAddress = String(repeating: "a", count: PlaceSuggestionLimits.addressMaxLength + 40)
        let location = SuggestedLocation(latitude: 1, longitude: 2, address: longAddress)

        try await service.submit(PlaceSuggestion(location: location, note: "ok"))

        let body = try #require(client.lastBodyJSON)
        let sent = try #require(body["address"] as? String)
        #expect(sent.count == PlaceSuggestionLimits.addressMaxLength)
    }

    @Test("submit rethrows the server error")
    func submitPropagatesFailure() async {
        let client = PlaceSuggestionStubNetworkClient(responseJSON: Self.createdJSON)
        client.sendError = APIError.httpStatus(400, message: nil)
        let service = makeService(client: client)

        await #expect(throws: APIError.self) {
            try await service.submit(PlaceSuggestion(location: Self.curitiba, note: "ok"))
        }
    }

    @Test("currentLocation pairs the position with the reverse-geocoded address")
    func currentLocationUsesGeocodedAddress() async throws {
        let locationService = PlaceSuggestionStubLocationService(
            coordinate: UserCoordinate(latitude: -25.43, longitude: -49.27)
        )
        let geocoder = PlaceSuggestionStubGeocoder(address: "Rua XV de Novembro, 1200")
        let service = makeService(locationService: locationService, geocoder: geocoder)

        let location = try await service.currentLocation()

        #expect(location.latitude == -25.43)
        #expect(location.longitude == -49.27)
        #expect(location.address == "Rua XV de Novembro, 1200")
    }

    @Test("currentLocation falls back to the coordinates when reverse geocoding finds nothing")
    func currentLocationFallsBackToCoordinates() async throws {
        let locationService = PlaceSuggestionStubLocationService(
            coordinate: UserCoordinate(latitude: -25.43, longitude: -49.27)
        )
        let service = makeService(locationService: locationService, geocoder: PlaceSuggestionStubGeocoder(address: nil))

        let location = try await service.currentLocation()

        #expect(location.address == "-25.430000, -49.270000")
    }

    @Test("currentLocation falls back to the coordinates when reverse geocoding fails")
    func currentLocationSurvivesGeocoderFailure() async throws {
        let geocoder = PlaceSuggestionStubGeocoder(address: nil)
        geocoder.error = URLError(.notConnectedToInternet)
        let service = makeService(geocoder: geocoder)

        let location = try await service.currentLocation()

        #expect(!location.address.isEmpty)
    }

    @Test("currentLocation passes a denied permission through")
    func currentLocationPropagatesDeniedPermission() async {
        let locationService = PlaceSuggestionStubLocationService()
        locationService.error = LocationMapError.authorizationDenied
        let service = makeService(locationService: locationService)

        await #expect(throws: LocationMapError.self) {
            try await service.currentLocation()
        }
    }

    @Test("the response decodes the Mongo _id")
    func responseDecodesMongoID() throws {
        let response = try JSONDecoder().decode(PlaceSuggestionResponse.self, from: Data(Self.createdJSON.utf8))

        #expect(response.id == "665f1c2e8a1b2c3d4e5f6a7b")
    }
}

private final class PlaceSuggestionStubNetworkClient: NetworkClient, @unchecked Sendable {
    private let responseJSON: String
    var sendError: Error?

    private(set) var lastSendPath: String?
    private(set) var lastSendMethod: HTTPMethod?
    private(set) var lastBody: Data?

    init(responseJSON: String) {
        self.responseJSON = responseJSON
    }

    var lastBodyJSON: [String: Any]? {
        guard let lastBody else { return nil }
        return (try? JSONSerialization.jsonObject(with: lastBody)) as? [String: Any]
    }

    func get<Response: Decodable>(path: String, queryItems: [URLQueryItem]) async throws -> Response {
        try JSONDecoder().decode(Response.self, from: Data(responseJSON.utf8))
    }

    func send<Body: Encodable, Response: Decodable>(
        path: String,
        method: HTTPMethod,
        body: Body
    ) async throws -> Response {
        lastSendPath = path
        lastSendMethod = method
        lastBody = try JSONEncoder().encode(body)
        if let sendError { throw sendError }
        return try JSONDecoder().decode(Response.self, from: Data(responseJSON.utf8))
    }

    func sendWithoutResponse(path: String, method: HTTPMethod) async throws {}
}

private final class PlaceSuggestionStubLocationService: LocationMapServicing, @unchecked Sendable {
    var coordinate = UserCoordinate(latitude: -25.428951, longitude: -49.2728171)
    var error: Error?

    init(coordinate: UserCoordinate? = nil) {
        if let coordinate { self.coordinate = coordinate }
    }

    func currentUserLocation() async throws -> UserCoordinate {
        if let error { throw error }
        return coordinate
    }

    func fetchNearbyPlaces(from coordinate: UserCoordinate) async throws -> [MapPlace] { [] }
}

private final class PlaceSuggestionStubGeocoder: PlaceGeocoding, @unchecked Sendable {
    var address: String?
    var error: Error?

    init(address: String? = nil) {
        self.address = address
    }

    func address(for coordinate: CLLocationCoordinate2D) async throws -> String? {
        if let error { throw error }
        return address
    }
}
