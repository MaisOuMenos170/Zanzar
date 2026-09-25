import Foundation

protocol WelcomeServicing: Sendable {
    // TODO: rename and adjust for the actual endpoint(s) this feature needs.
    func submitWelcome(_ request: WelcomeRequest) async throws -> WelcomeResponse
}

struct WelcomeRequest: Encodable {
    // TODO: add the fields sent to the API
}

struct WelcomeResponse: Decodable {
    // TODO: add the fields returned by the API
}

final class WelcomeService: WelcomeServicing {
    private let client: NetworkClient

    init(client: NetworkClient = URLSessionNetworkClient.shared) {
        self.client = client
    }

    func submitWelcome(_ request: WelcomeRequest) async throws -> WelcomeResponse {
        // TODO: replace with the real path
        try await client.send(path: "/welcome", method: .post, body: request)
    }
}
