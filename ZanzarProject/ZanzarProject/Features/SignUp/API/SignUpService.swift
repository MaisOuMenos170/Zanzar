import Foundation

protocol SignUpServicing: Sendable {
    // TODO: rename and adjust for the actual endpoint(s) this feature needs.
    func submitSignUp(_ request: SignUpRequest) async throws -> SignUpResponse
}

struct SignUpRequest: Encodable {
    // TODO: add the fields sent to the API
}

struct SignUpResponse: Decodable {
    // TODO: add the fields returned by the API
}

final class SignUpService: SignUpServicing {
    private let client: NetworkClient

    init(client: NetworkClient = URLSessionNetworkClient.shared) {
        self.client = client
    }

    func submitSignUp(_ request: SignUpRequest) async throws -> SignUpResponse {
        // TODO: replace with the real path
        try await client.send(path: "/signUp", method: .post, body: request)
    }
}
