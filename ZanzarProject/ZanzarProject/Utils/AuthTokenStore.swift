import Foundation

// Safety invariant for `@unchecked Sendable`: `token` is only read or written while holding `lock`.
nonisolated final class AuthTokenStore: @unchecked Sendable {
    static let shared = AuthTokenStore()

    private let lock = NSLock()
    private var token: String?

    private init() {}

    func getToken() -> String? {
        lock.lock()
        defer { lock.unlock() }
        return token
    }

    var userID: String? {
        getToken().flatMap(JWTDecoder.userID(from:))
    }

    func setToken(_ token: String?) {
        lock.lock()
        defer { lock.unlock() }
        self.token = token
    }
}
