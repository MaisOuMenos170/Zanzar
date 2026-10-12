import Foundation

protocol LoginServicing: Sendable {
    func submitLogin(_ request: LoginRequest) async throws -> LoginResponse
}

struct LoginRequest: Encodable, Sendable {
    let email: String
    let password: String
}

struct LoginResponse: Decodable, Sendable {
    let token: String
}

final class LoginService: LoginServicing {
    private let client: NetworkClient

    init(client: NetworkClient = URLSessionNetworkClient.shared) {
        self.client = client
    }

    func submitLogin(_ request: LoginRequest) async throws -> LoginResponse {
        AppLog.login.info("Submitting login...")
        do {
            let response: LoginResponse = try await client.send(path: "login", method: .post, body: request)
            AppLog.login.info("Login request succeeded")
            return response
        } catch {
            AppLog.login.error("Login request failed", error: error)
            throw error
        }
    }
}
