import Foundation
@testable import ZanzarProject

final class InMemoryAuthTokenStore: AuthTokenPersisting, @unchecked Sendable {
    private let lock = NSLock()
    private var tokens: AuthTokens?

    func saveTokens(_ tokens: AuthTokens) throws {
        lock.lock()
        defer { lock.unlock() }
        self.tokens = tokens
    }

    func readTokens() -> AuthTokens? {
        lock.lock()
        defer { lock.unlock() }
        return tokens
    }

    func deleteTokens() throws {
        lock.lock()
        defer { lock.unlock() }
        tokens = nil
    }
}
