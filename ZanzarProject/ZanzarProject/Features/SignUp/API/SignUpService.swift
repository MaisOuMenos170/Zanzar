import Foundation

protocol SignUpServicing: Sendable {
    func submitSignUp(_ request: SignUpRequest) async throws -> SignUpResponse
}

struct SignUpRequest: Encodable, Sendable {
    let email: String
    let username: String
    let password: String
}

struct SignUpResponse: Decodable, Sendable {
    let id: String

    private enum CodingKeys: String, CodingKey {
        case id = "_id"
    }
}

final class SignUpService: SignUpServicing {
    private let client: NetworkClient

    init(client: NetworkClient = URLSessionNetworkClient.shared) {
        self.client = client
    }

    func submitSignUp(_ request: SignUpRequest) async throws -> SignUpResponse {
        try await client.send(path: "register", method: .post, body: request)
    }
}
