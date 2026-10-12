import Foundation
import Testing
@testable import ZanzarProject

@MainActor
@Suite("LoginService")
struct LoginServiceTests {
    @Test("submitLogin posts credentials and decodes the token")
    func submitLogin() async throws {
        let client = StubNetworkClient(responseJSON: #"{"token":"jwt-token"}"#)
        let service = LoginService(client: client)

        let response = try await service.submitLogin(
            LoginRequest(email: "ana@example.com", password: "secret12")
        )

        #expect(response.token == "jwt-token")
        #expect(client.lastSendPath == "login")
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
