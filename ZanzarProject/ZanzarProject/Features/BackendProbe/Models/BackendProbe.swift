import Foundation

struct HealthCheck: Equatable, Sendable {
    let status: String

    var isHealthy: Bool {
        status == "ok"
    }
}

enum BackendUserRole: String, Sendable {
    case admin
    case user
    case guest
}

struct NewBackendUser: Sendable {
    let email: String
    let name: String
    let role: BackendUserRole

    init(email: String, name: String, role: BackendUserRole = .user) {
        self.email = email
        self.name = name
        self.role = role
    }
}

struct BackendUser: Identifiable, Equatable, Sendable {
    let id: String
    let email: String
    let name: String
    let role: BackendUserRole
}
