import Foundation

nonisolated struct AuthTokens: Sendable, Equatable {
    let accessToken: String
    let refreshToken: String

    init?(accessToken: String, refreshToken: String) {
        let access = accessToken.trimmingCharacters(in: .whitespacesAndNewlines)
        let refresh = refreshToken.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !access.isEmpty, !refresh.isEmpty else { return nil }
        self.accessToken = access
        self.refreshToken = refresh
    }
}
