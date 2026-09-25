import Foundation

protocol LoginServicing: Sendable {
    // TODO: rename and adjust for the actual endpoint(s) this feature needs.
    func submitLogin(_ request: LoginRequest) async throws -> LoginResponse
}

struct LoginRequest: Encodable {
    // TODO: add the fields sent to the API
}

struct LoginResponse: Decodable {
    // TODO: add the fields returned by the API
}

final class LoginService: LoginServicing {
    private let client: NetworkClient

    init(client: NetworkClient = URLSessionNetworkClient.shared) {
        self.client = client
    }

    func submitLogin(_ request: LoginRequest) async throws -> LoginResponse {
        // TODO: replace with the real path
        try await client.send(path: "/login", method: .post, body: request)
    }
}
