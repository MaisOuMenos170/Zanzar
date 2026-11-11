import Foundation
import Testing
@testable import ZanzarProject

@MainActor
@Suite("PasswordResetService")
struct PasswordResetServiceTests {
    @Test("requestCode posts the email to password/forgot")
    func requestCode() async throws {
        let client = RecordingNetworkClient()
        let service = PasswordResetService(client: client)

        try await service.requestCode(email: "ana@example.com")

        #expect(client.lastPath == "password/forgot")
        #expect(client.lastMethod == .post)
        #expect(try client.lastJSON() == ["email": "ana@example.com"])
    }

    @Test("verify with a code sends only email and code, and returns the reset token")
    func verifyCode() async throws {
        let client = RecordingNetworkClient(responseJSON: #"{"resetToken":"reset-123"}"#)
        let service = PasswordResetService(client: client)

        let token = try await service.verify(.code(email: "ana@example.com", code: "123456"))

        #expect(token == "reset-123")
        #expect(client.lastPath == "password/verify")
        #expect(client.lastMethod == .post)
        #expect(try client.lastJSON() == ["email": "ana@example.com", "code": "123456"])
    }

    @Test("verify with a link sends only the token")
    func verifyLink() async throws {
        let client = RecordingNetworkClient(responseJSON: #"{"resetToken":"reset-123"}"#)
        let service = PasswordResetService(client: client)

        _ = try await service.verify(.link(token: "link-token"))

        #expect(try client.lastJSON() == ["token": "link-token"])
    }

    @Test("resetPassword posts the reset token and the new password")
    func resetPassword() async throws {
        let client = RecordingNetworkClient()
        let service = PasswordResetService(client: client)

        try await service.resetPassword(resetToken: "reset-123", newPassword: "nova1234")

        #expect(client.lastPath == "password/reset")
        #expect(client.lastMethod == .post)
        #expect(try client.lastJSON() == ["resetToken": "reset-123", "newPassword": "nova1234"])
    }

    @Test("errors from the client reach the caller")
    func propagatesErrors() async {
        let client = RecordingNetworkClient(error: APIError.httpStatus(400, message: "Invalid or expired code"))
        let service = PasswordResetService(client: client)

        await #expect(throws: APIError.self) {
            _ = try await service.verify(.code(email: "ana@example.com", code: "000000"))
        }
    }
}

private final class RecordingNetworkClient: NetworkClient, @unchecked Sendable {
    private let responseJSON: String
    private let error: Error?
    private(set) var lastPath: String?
    private(set) var lastMethod: HTTPMethod?
    private(set) var lastBody: Data?

    init(responseJSON: String = "{}", error: Error? = nil) {
        self.responseJSON = responseJSON
        self.error = error
    }

    func lastJSON() throws -> [String: String] {
        let body = try #require(lastBody)
        return try #require(JSONSerialization.jsonObject(with: body) as? [String: String])
    }

    func get<Response: Decodable>(path: String, queryItems: [URLQueryItem]) async throws -> Response {
        throw APIError.invalidRequest
    }

    func send<Body: Encodable, Response: Decodable>(
        path: String,
        method: HTTPMethod,
        body: Body
    ) async throws -> Response {
        try record(path: path, method: method, body: body)
        return try JSONDecoder().decode(Response.self, from: Data(responseJSON.utf8))
    }

    func sendWithoutResponse(path: String, method: HTTPMethod) async throws {
        throw APIError.invalidRequest
    }

    func sendWithoutResponse<Body: Encodable>(path: String, method: HTTPMethod, body: Body) async throws {
        try record(path: path, method: method, body: body)
    }

    private func record<Body: Encodable>(path: String, method: HTTPMethod, body: Body) throws {
        lastPath = path
        lastMethod = method
        lastBody = try JSONEncoder().encode(body)
        if let error { throw error }
    }
}
