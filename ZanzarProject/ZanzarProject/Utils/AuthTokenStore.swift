import Foundation

// Safety invariant for `@unchecked Sendable`: `tokens` is only read or written while holding `lock`.
nonisolated final class AuthTokenStore: @unchecked Sendable {
    static let shared = AuthTokenStore()

    private let lock = NSLock()
    private var tokens: AuthTokens?

    init() {}

    func getToken() -> String? {
        lock.lock()
        defer { lock.unlock() }
        return tokens?.accessToken
    }

    func getRefreshToken() -> String? {
        lock.lock()
        defer { lock.unlock() }
        return tokens?.refreshToken
    }

    var userID: String? {
        getToken().flatMap(JWTDecoder.userID(from:))
    }

    func setTokens(_ tokens: AuthTokens?) {
        lock.lock()
        defer { lock.unlock() }
        self.tokens = tokens
    }
}
