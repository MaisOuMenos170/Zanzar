import Foundation
import Testing
@testable import ZanzarProject

@Suite("RatingPromptService")
struct RatingPromptServiceTests {
    @Test("hasRated returns false on 404")
    func hasRatedMissing() async throws {
        let client = ThrowingNetworkClient(getError: APIError.httpStatus(404, message: nil))
        let service = RatingPromptService(client: client)

        let hasRated = try await service.hasRated(placeID: "ChIJ1")

        #expect(!hasRated)
    }

    @Test("submitRating decodes impression counts")
    func submitRating() async throws {
        let json = #"{"impressionTag":"happy","placeId":"ChIJ1","impressionCounts":{"happy":3}}"#
        let client = StubNetworkClient(responseJSON: json)
        let service = RatingPromptService(client: client)

        let submission = try await service.submitRating(placeID: "ChIJ1", impressionTag: .happy)

        #expect(submission.impressionTag == .happy)
        #expect(submission.impressionCounts?["happy"] == 3)
        #expect(client.lastSendPath == "rating")
    }
}

private final class StubNetworkClient: NetworkClient, @unchecked Sendable {
    private let responseJSON: String
    private(set) var lastSendPath: String?

    init(responseJSON: String) {
        self.responseJSON = responseJSON
    }

    func get<Response: Decodable>(path: String, queryItems: [URLQueryItem]) async throws -> Response {
        try JSONDecoder().decode(Response.self, from: Data(responseJSON.utf8))
    }

    func send<Body: Encodable, Response: Decodable>(path: String, method: HTTPMethod, body: Body) async throws -> Response {
        lastSendPath = path
        return try JSONDecoder().decode(Response.self, from: Data(responseJSON.utf8))
    }

    func sendWithoutResponse(path: String, method: HTTPMethod) async throws {}
}

private final class ThrowingNetworkClient: NetworkClient, @unchecked Sendable {
    private let getError: Error

    init(getError: Error) {
        self.getError = getError
    }

    func get<Response: Decodable>(path: String, queryItems: [URLQueryItem]) async throws -> Response {
        throw getError
    }

    func send<Body: Encodable, Response: Decodable>(path: String, method: HTTPMethod, body: Body) async throws -> Response {
        throw getError
    }

    func sendWithoutResponse(path: String, method: HTTPMethod) async throws {
        throw getError
    }
}
