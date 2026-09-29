import Foundation
@testable import ZanzarProject

final class InMemoryAuthTokenStore: AuthTokenPersisting, @unchecked Sendable {
    private let lock = NSLock()
    private var token: String?

    func saveToken(_ token: String) throws {
        lock.lock()
        defer { lock.unlock() }
        self.token = token
    }

    func readToken() -> String? {
        lock.lock()
        defer { lock.unlock() }
        return token
    }

    func deleteToken() throws {
        lock.lock()
        defer { lock.unlock() }
        token = nil
    }
}
