import Foundation
import Testing
@testable import ZanzarProject

@MainActor
@Suite("ProfileService")
struct ProfileServiceTests {
    private static let readmeJSON = """
    {
      "username": "tiago",
      "checkInCount": 12,
      "completedItinerariesCount": 2,
      "stampsCount": 9,
      "recentCheckIns": [
        {
          "placeId": "ChIJ1",
          "placeName": "Bar do Zé",
          "datetime": "2026-10-05T18:30:00.000Z",
          "photoReference": "AUacSh",
          "stamp": { "stampId": "stamp_bar", "imageUrl": "/assets/stamps/bar.png" }
        },
        {
          "placeId": "ChIJ2",
          "placeName": null,
          "datetime": "2026-10-04T10:00:00Z",
          "photoReference": null,
          "stamp": null
        },
        {
          "placeId": "ChIJ3",
          "placeName": "Lugar novo",
          "datetime": "2026-10-03T10:00:00.000Z",
          "photoReference": null,
          "stamp": { "stampId": "stamp_future", "imageUrl": "/assets/stamps/future.png" }
        }
      ]
    }
    """

    // MARK: - Mapping

    @Test("maps the backend payload to the domain profile")
    func mapsSummary() throws {
        let profile = try Self.decodeProfile(Self.readmeJSON)

        #expect(profile.summary == ProfileSummary(name: "tiago", checkInCount: 12, itineraryCount: 2, sealCount: 9))
        #expect(profile.recentCheckIns.count == 3)
    }

    @Test("maps check-in fields, including fractional-second dates and nullable values")
    func mapsCheckIns() throws {
        let checkIns = try Self.decodeProfile(Self.readmeJSON).recentCheckIns

        #expect(checkIns[0].placeName == "Bar do Zé")
        #expect(checkIns[0].photoReference == "AUacSh")
        #expect(checkIns[0].sealCategory == .bar)
        #expect(checkIns[0].date == Date(timeIntervalSince1970: 1_791_225_000))

        #expect(checkIns[1].placeName == nil)
        #expect(checkIns[1].photoReference == nil)
        #expect(checkIns[1].sealCategory == nil)
        #expect(checkIns[1].date == Date(timeIntervalSince1970: 1_791_108_000))
    }

    @Test("an unknown stamp id shows no seal instead of a wrong one")
    func unknownStampHasNoSeal() throws {
        let checkIns = try Self.decodeProfile(Self.readmeJSON).recentCheckIns

        #expect(checkIns[2].sealCategory == nil)
    }

    @Test("check-in ids are unique per place and moment")
    func checkInIDsAreUnique() throws {
        let checkIns = try Self.decodeProfile(Self.readmeJSON).recentCheckIns

        #expect(Set(checkIns.map(\.id)).count == checkIns.count)
    }

    @Test("a check-in opens the place detail with the place id and no distance")
    func checkInMapsToPlace() throws {
        let checkIn = try Self.decodeProfile(Self.readmeJSON).recentCheckIns[0]

        #expect(checkIn.placeID == "ChIJ1")
        #expect(checkIn.mapPlace.id == "ChIJ1")
        #expect(checkIn.mapPlace.category == .bar)
        #expect(checkIn.mapPlace.distanceMeters == nil)
    }

    @Test("an unparseable datetime fails the mapping")
    func invalidDateThrows() throws {
        let json = Self.readmeJSON.replacingOccurrences(of: "2026-10-04T10:00:00Z", with: "yesterday")

        #expect(throws: APIError.self) {
            try Self.decodeProfile(json)
        }
    }

    // MARK: - Requests

    @Test("fetchProfile requests the user's profile path with the limit")
    func fetchProfileRequest() async throws {
        let client = StubNetworkClient(responseJSON: Self.readmeJSON)
        let service = ProfileService(client: client)

        let profile = try await service.fetchProfile(userID: "user-1", limit: 4)

        #expect(client.lastGetPath == "user/user-1/profile")
        #expect(client.lastQueryItems == [URLQueryItem(name: "limit", value: "4")])
        #expect(profile.summary.name == "tiago")
    }

    @Test("logout posts to /logout without a body")
    func logoutRequest() async throws {
        let client = StubNetworkClient(responseJSON: "{}")
        let service = ProfileService(client: client)

        try await service.logout()

        #expect(client.lastEmptyPath == "logout")
        #expect(client.lastEmptyMethod == .post)
    }

    @Test("logout propagates server errors")
    func logoutPropagatesErrors() async {
        let client = StubNetworkClient(responseJSON: "{}")
        client.emptyError = APIError.httpStatus(401, message: nil)
        let service = ProfileService(client: client)

        await #expect(throws: APIError.self) {
            try await service.logout()
        }
    }

    private static func decodeProfile(_ json: String) throws -> Profile {
        try JSONDecoder().decode(ProfileAPIResponse.self, from: Data(json.utf8)).makeProfile()
    }
}

/// Records the calls it receives; `get` decodes whatever JSON it was given.
private final class StubNetworkClient: NetworkClient, @unchecked Sendable {
    private let responseJSON: String
    var emptyError: Error?

    private(set) var lastGetPath: String?
    private(set) var lastQueryItems: [URLQueryItem]?
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
        try JSONDecoder().decode(Response.self, from: Data(responseJSON.utf8))
    }

    func sendWithoutResponse(path: String, method: HTTPMethod) async throws {
        lastEmptyPath = path
        lastEmptyMethod = method
        if let emptyError { throw emptyError }
    }
}
