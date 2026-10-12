import Foundation
import Testing
@testable import ZanzarProject

@MainActor
@Suite("SignUpService")
struct SignUpServiceTests {
    @Test("submitSignUp posts the payload and decodes the user id")
    func submitSignUp() async throws {
        let client = StubNetworkClient(responseJSON: #"{"_id":"674abc123def456789012345"}"#)
        let service = SignUpService(client: client)

        let response = try await service.submitSignUp(
            SignUpRequest(email: "ana@example.com", username: "ana", password: "secret12")
        )

        #expect(response.id == "674abc123def456789012345")
        #expect(client.lastSendPath == "register")
        #expect(client.lastSendMethod == .post)
    }
}

private final class StubNetworkClient: NetworkClient, @unchecked Sendable {
    private let responseJSON: String
    private(set) var lastSendPath: String?
    private(set) var lastSendMethod: HTTPMethod?

    init(responseJSON: String) {
        self.responseJSON = responseJSON
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
        return try JSONDecoder().decode(Response.self, from: Data(responseJSON.utf8))
    }

    func sendWithoutResponse(path: String, method: HTTPMethod) async throws {}
}
