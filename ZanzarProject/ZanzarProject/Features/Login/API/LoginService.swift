import Foundation

protocol LoginServicing: Sendable {
    func submitLogin(_ request: LoginRequest) async throws -> LoginResponse
    func submitAppleLogin(_ request: AppleLoginRequest) async throws -> LoginResponse
}

struct LoginRequest: Encodable, Sendable {
    let email: String
    let password: String
}

/// Body of `POST /login/apple`. `nonce` is the raw value; Apple only received its SHA-256.
/// `fullName` is only available on the first authorization, so the backend uses it to build the username.
struct AppleLoginRequest: Encodable, Sendable {
    struct FullName: Encodable, Sendable {
        let givenName: String?
        let familyName: String?
    }

    let identityToken: String
    let nonce: String
    let fullName: FullName?
}

struct LoginResponse: Decodable, Sendable {
    let token: String
    let refreshToken: String
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

    func submitAppleLogin(_ request: AppleLoginRequest) async throws -> LoginResponse {
        AppLog.login.info("Submitting Apple login...")
        do {
            let response: LoginResponse = try await client.send(path: "login/apple", method: .post, body: request)
            AppLog.login.info("Apple login request succeeded")
            return response
        } catch {
            AppLog.login.error("Apple login request failed", error: error)
            throw error
        }
    }
}
