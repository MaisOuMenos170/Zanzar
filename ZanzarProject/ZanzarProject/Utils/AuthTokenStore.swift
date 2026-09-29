import Foundation

final class AuthTokenStore: @unchecked Sendable {
    static let shared = AuthTokenStore()

    private let lock = NSLock()
    private var token: String?

    private init() {}

    func getToken() -> String? {
        lock.lock()
        defer { lock.unlock() }
        return token
    }

    func setToken(_ token: String?) {
        lock.lock()
        defer { lock.unlock() }
        self.token = token
    }
}
