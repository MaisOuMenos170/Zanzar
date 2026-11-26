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
      "status": "needs_review",
      "name": "Padaria Central",
      "decisionReason": "not_confirmed",
      "placeId": null,
      "decidedAt": null,
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

    private static let padaria = PlaceSuggestion(name: "Padaria Central", location: curitiba, note: "")

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

    @Test("submit posts the name, address, coordinates and note to place-suggestions")
    func submitSendsExpectedRequest() async throws {
        let client = PlaceSuggestionStubNetworkClient(responseJSON: Self.createdJSON)
        let service = makeService(client: client)

        let suggestion = PlaceSuggestion(name: "Padaria Central", location: Self.curitiba, note: "Vale a pena")
        _ = try await service.submit(suggestion)

        #expect(client.lastSendPath == "place-suggestions")
        #expect(client.lastSendMethod == .post)
        let body = try #require(client.lastBodyJSON)
        #expect(body["address"] as? String == "Rua XV de Novembro, 1200")
        #expect(body["name"] as? String == "Padaria Central")
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

        _ = try await service.submit(PlaceSuggestion(name: "Padaria", location: Self.curitiba, note: "   \n "))

        let body = try #require(client.lastBodyJSON)
        #expect(body["note"] == nil)
    }

    @Test("submit cuts an address longer than the backend limit")
    func submitTruncatesAddress() async throws {
        let client = PlaceSuggestionStubNetworkClient(responseJSON: Self.createdJSON)
        let service = makeService(client: client)
        let longAddress = String(repeating: "a", count: PlaceSuggestionLimits.addressMaxLength + 40)
        let location = SuggestedLocation(latitude: 1, longitude: 2, address: longAddress)

        _ = try await service.submit(PlaceSuggestion(name: "Padaria", location: location, note: "ok"))

        let body = try #require(client.lastBodyJSON)
        let sent = try #require(body["address"] as? String)
        #expect(sent.count == PlaceSuggestionLimits.addressMaxLength)
    }

    @Test("submit leaves the name out when there is none")
    func submitOmitsBlankName() async throws {
        let client = PlaceSuggestionStubNetworkClient(responseJSON: Self.createdJSON)
        let service = makeService(client: client)

        _ = try await service.submit(PlaceSuggestion(name: "  ", location: Self.curitiba, note: ""))

        let body = try #require(client.lastBodyJSON)
        #expect(body["name"] == nil)
    }

    @Test("submit says the suggestion waits for a person when the place is not confirmed")
    func submitWaitingForReview() async throws {
        let service = makeService()

        let outcome = try await service.submit(Self.padaria)

        #expect(outcome == .success)
    }

    @Test("submit says the place is in the app when the backend approved it")
    func submitApproved() async throws {
        let json = Self.createdJSON.replacingOccurrences(of: "needs_review", with: "approved")
        let service = makeService(client: PlaceSuggestionStubNetworkClient(responseJSON: json))

        let outcome = try await service.submit(Self.padaria)

        #expect(outcome == .published(placeName: "Padaria Central"))
    }

    @Test("submit says why when the backend refused the suggestion")
    func submitRefused() async throws {
        let json = Self.createdJSON
            .replacingOccurrences(of: "needs_review", with: "rejected")
            .replacingOccurrences(of: "not_confirmed", with: "duplicate")
        let service = makeService(client: PlaceSuggestionStubNetworkClient(responseJSON: json))

        let outcome = try await service.submit(Self.padaria)

        #expect(outcome == .refused(.duplicate))
    }

    @Test("submit rethrows the server error")
    func submitPropagatesFailure() async {
        let client = PlaceSuggestionStubNetworkClient(responseJSON: Self.createdJSON)
        client.sendError = APIError.httpStatus(400, message: nil)
        let service = makeService(client: client)

        await #expect(throws: APIError.self) {
            _ = try await service.submit(PlaceSuggestion(name: "Padaria", location: Self.curitiba, note: "ok"))
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

    @Test("search asks Apple Maps for named places and addresses, near the user when known")
    func searchUsesGeocoder() async throws {
        let place = SuggestedPlace(name: "Jardim Botânico", address: "Curitiba", latitude: -25.44, longitude: -49.24)
        let geocoder = PlaceSuggestionStubGeocoder()
        geocoder.places = [place]
        let service = makeService(geocoder: geocoder)

        let found = try await service.searchPlaces(query: "jardim", near: Self.curitiba)

        #expect(found == [place])
        #expect(geocoder.lastQuery == "jardim")
        #expect(geocoder.lastIncludedPointsOfInterest == true)
        #expect(geocoder.lastNear?.latitude == -25.43)
    }

    @Test("searching without a position passes none")
    func searchWithoutPosition() async throws {
        let geocoder = PlaceSuggestionStubGeocoder()
        let service = makeService(geocoder: geocoder)

        _ = try await service.searchPlaces(query: "jardim", near: nil)

        #expect(geocoder.lastNear == nil)
    }

    @Test("resolving an address looks only at addresses and takes the first one")
    func resolveAddressTakesFirstAddress() async throws {
        let first = SuggestedPlace(name: nil, address: "Rua A, 1", latitude: -25.4, longitude: -49.2)
        let second = SuggestedPlace(name: nil, address: "Rua A, 2", latitude: -25.5, longitude: -49.3)
        let geocoder = PlaceSuggestionStubGeocoder()
        geocoder.places = [first, second]
        let service = makeService(geocoder: geocoder)

        let found = try await service.resolveAddress("Rua A, 1", near: nil)

        #expect(found == first)
        #expect(geocoder.lastIncludedPointsOfInterest == false)
    }

    @Test("an address Apple Maps cannot place resolves to nothing")
    func resolveAddressWithoutMatch() async throws {
        let service = makeService(geocoder: PlaceSuggestionStubGeocoder())

        #expect(try await service.resolveAddress("xyz", near: nil) == nil)
    }

    @Test("a search failure is passed through")
    func searchFailure() async {
        let geocoder = PlaceSuggestionStubGeocoder()
        geocoder.error = URLError(.notConnectedToInternet)
        let service = makeService(geocoder: geocoder)

        await #expect(throws: URLError.self) {
            _ = try await service.searchPlaces(query: "jardim", near: nil)
        }
    }

    @Test("the response decodes the Mongo _id")
    func responseDecodesMongoID() throws {
        let response = try JSONDecoder().decode(MySuggestionAPIResponse.self, from: Data(Self.createdJSON.utf8))

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
    var places: [SuggestedPlace] = []
    var error: Error?

    private(set) var lastQuery: String?
    private(set) var lastNear: CLLocationCoordinate2D?
    private(set) var lastIncludedPointsOfInterest: Bool?

    init(address: String? = nil) {
        self.address = address
    }

    func address(for coordinate: CLLocationCoordinate2D) async throws -> String? {
        if let error { throw error }
        return address
    }

    func places(
        matching query: String,
        near: CLLocationCoordinate2D?,
        includingPointsOfInterest: Bool
    ) async throws -> [SuggestedPlace] {
        lastQuery = query
        lastNear = near
        lastIncludedPointsOfInterest = includingPointsOfInterest
        if let error { throw error }
        return places
    }
}
