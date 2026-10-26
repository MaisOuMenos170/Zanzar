import Foundation

actor SessionRefresher {
    static let shared = SessionRefresher(
        baseURL: APIConfiguration.baseURL,
        onSessionExpired: {
            Task { @MainActor in
                NotificationCenter.default.post(name: AppNotification.sessionExpired, object: nil)
            }
        }
    )

    private struct RefreshRequest: Encodable {
        let refreshToken: String
    }

    private struct RefreshResponse: Decodable {
        let token: String
        let refreshToken: String
    }

    private let baseURL: URL
    private let session: URLSession
    private let persistence: AuthTokenPersisting
    private let tokenStore: AuthTokenStore
    private let onSessionExpired: @Sendable () -> Void
    private var inFlight: Task<Void, Error>?

    init(
        baseURL: URL,
        session: URLSession = .shared,
        persistence: AuthTokenPersisting = KeychainStore(),
        tokenStore: AuthTokenStore = .shared,
        onSessionExpired: @escaping @Sendable () -> Void
    ) {
        self.baseURL = baseURL
        self.session = session
        self.persistence = persistence
        self.tokenStore = tokenStore
        self.onSessionExpired = onSessionExpired
    }

    func refresh(after failedAccessToken: String) async throws {
        guard let currentAccessToken = tokenStore.getToken() else {
            throw APIError.httpStatus(401, message: nil)
        }
        if currentAccessToken != failedAccessToken {
            // A concurrent request already renewed the tokens; the caller just retries with them.
            return
        }
        if let inFlight {
            return try await inFlight.value
        }

        let task = Task { try await performRefresh() }
        inFlight = task
        defer { inFlight = nil }
        try await task.value
    }

    func expireSession() {
        guard tokenStore.getRefreshToken() != nil else { return }
        tokenStore.setTokens(nil)
        do {
            try persistence.deleteTokens()
        } catch {
            AppLog.auth.error("Failed to delete tokens from keychain after session expired", error: error)
        }
        AppLog.auth.warning("Session expired, signing out")
        onSessionExpired()
    }

    private func performRefresh() async throws {
        guard let refreshToken = tokenStore.getRefreshToken() else {
            expireSession()
            throw APIError.httpStatus(401, message: nil)
        }

        var request = URLRequest(url: baseURL.appendingPathComponent("refresh"))
        request.httpMethod = HTTPMethod.post.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(RefreshRequest(refreshToken: refreshToken))

        AppLog.auth.info("Refreshing access token")
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        let status = httpResponse.statusCode
        switch status {
        case 200..<300:
            break
        case 401:
            expireSession()
            throw APIError.from(data: data, statusCode: status)
        case 429:
            let retryAfter = URLSessionNetworkClient.retryAfter(from: httpResponse, now: Date())
            AppLog.auth.warning("Refresh rate limited (429)")
            throw APIError.rateLimited(retryAfter: retryAfter)
        default:
            AppLog.auth.warning("Refresh failed with status \(status), keeping the session")
            throw APIError.from(data: data, statusCode: status)
        }

        guard let decoded = try? JSONDecoder().decode(RefreshResponse.self, from: data),
              let tokens = AuthTokens(accessToken: decoded.token, refreshToken: decoded.refreshToken) else {
            AppLog.auth.error("Refresh response could not be decoded", error: APIError.decodingFailed)
            throw APIError.decodingFailed
        }

        // In-memory state first: if the Keychain write fails, this launch keeps working with the rotated token.
        tokenStore.setTokens(tokens)
        do {
            try persistence.saveTokens(tokens)
        } catch {
            AppLog.auth.error("Failed to save refreshed tokens to keychain", error: error)
        }
        AppLog.auth.info("Access token refreshed")
    }
}
