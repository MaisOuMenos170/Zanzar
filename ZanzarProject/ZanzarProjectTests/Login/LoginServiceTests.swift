import Foundation
import Testing
@testable import ZanzarProject

@MainActor
@Suite("LoginService")
struct LoginServiceTests {
    @Test("submitLogin posts credentials and decodes the tokens")
    func submitLogin() async throws {
        let client = StubNetworkClient(responseJSON: #"{"token":"jwt-token","refreshToken":"refresh-token"}"#)
        let service = LoginService(client: client)

        let response = try await service.submitLogin(
            LoginRequest(email: "ana@example.com", password: "secret12")
        )

        #expect(response.token == "jwt-token")
        #expect(response.refreshToken == "refresh-token")
        #expect(client.lastSendPath == "login")
        #expect(client.lastSendMethod == .post)
    }

    @Test("submitAppleLogin posts the token, raw nonce and name to login/apple and decodes the tokens")
    func submitAppleLogin() async throws {
        let client = StubNetworkClient(responseJSON: #"{"token":"jwt-token","refreshToken":"refresh-token"}"#)
        let service = LoginService(client: client)

        let response = try await service.submitAppleLogin(
            AppleLoginRequest(
                identityToken: "apple-token",
                nonce: "raw-nonce",
                fullName: .init(givenName: "Tiago", familyName: "Prestes")
            )
        )

        #expect(response.token == "jwt-token")
        #expect(response.refreshToken == "refresh-token")
        #expect(client.lastSendPath == "login/apple")
        #expect(client.lastSendMethod == .post)

        let body = try #require(client.lastSendBody)
        let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
        #expect(json["identityToken"] as? String == "apple-token")
        #expect(json["nonce"] as? String == "raw-nonce")
        let fullName = try #require(json["fullName"] as? [String: Any])
        #expect(fullName["givenName"] as? String == "Tiago")
        #expect(fullName["familyName"] as? String == "Prestes")
    }

    @Test("submitAppleLogin leaves fullName out when Apple did not provide one")
    func submitAppleLoginWithoutName() async throws {
        let client = StubNetworkClient(responseJSON: #"{"token":"jwt-token","refreshToken":"refresh-token"}"#)
        let service = LoginService(client: client)

        _ = try await service.submitAppleLogin(
            AppleLoginRequest(identityToken: "apple-token", nonce: "raw-nonce", fullName: nil)
        )

        let body = try #require(client.lastSendBody)
        let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
        #expect(json["fullName"] == nil)
    }
}

private final class StubNetworkClient: NetworkClient, @unchecked Sendable {
    private let responseJSON: String
    private(set) var lastSendPath: String?
    private(set) var lastSendMethod: HTTPMethod?
    private(set) var lastSendBody: Data?

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
        lastSendBody = try JSONEncoder().encode(body)
        return try JSONDecoder().decode(Response.self, from: Data(responseJSON.utf8))
    }

    func sendWithoutResponse(path: String, method: HTTPMethod) async throws {}
}
