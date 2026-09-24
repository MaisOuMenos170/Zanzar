import Foundation

protocol BackendProbeServicing: Sendable {
    func fetchHealth() async throws -> HealthCheck
    func createUser(_ input: NewBackendUser) async throws -> BackendUser
    func fetchUser(id: String) async throws -> BackendUser
}

struct CreateUserRequest: Encodable {
    let email: String
    let name: String
    let role: String
}

struct HealthCheckResponse: Decodable {
    let status: String
}

struct UserResponse: Decodable {
    let id: String
    let email: String
    let name: String
    let role: String

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case email
        case name
        case role
    }
}

final class BackendProbeService: BackendProbeServicing {
    private let client: NetworkClient

    init(client: NetworkClient = URLSessionNetworkClient.shared) {
        self.client = client
    }

    func fetchHealth() async throws -> HealthCheck {
        let response: HealthCheckResponse = try await client.get(path: "health")
        return HealthCheck(status: response.status)
    }

    func createUser(_ input: NewBackendUser) async throws -> BackendUser {
        let request = CreateUserRequest(
            email: input.email,
            name: input.name,
            role: input.role.rawValue
        )
        let response: UserResponse = try await client.send(path: "user", method: .post, body: request)
        return BackendUser(response: response)
    }

    func fetchUser(id: String) async throws -> BackendUser {
        let response: UserResponse = try await client.get(path: "user/\(id)")
        return BackendUser(response: response)
    }
}

private extension BackendUser {
    init(response: UserResponse) {
        self.init(
            id: response.id,
            email: response.email,
            name: response.name,
            role: BackendUserRole(rawValue: response.role) ?? .user
        )
    }
}
