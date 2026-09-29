import Foundation
import Observation

enum AuthSessionError: Error, Sendable {
    case invalidToken
}

@MainActor
@Observable
final class AuthSession {
    private(set) var token: String?

    var isAuthenticated: Bool {
        token != nil
    }

    private let keychain: AuthTokenPersisting
    private let tokenStore: AuthTokenStore

    init(
        keychain: AuthTokenPersisting = KeychainStore(),
        tokenStore: AuthTokenStore = .shared
    ) {
        self.keychain = keychain
        self.tokenStore = tokenStore
        restore()
    }

    func restore() {
        guard let storedToken = keychain.readToken(), !storedToken.isEmpty else {
            return
        }
        token = storedToken
        tokenStore.setToken(storedToken)
    }

    func signIn(token: String) throws {
        let trimmedToken = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedToken.isEmpty else {
            throw AuthSessionError.invalidToken
        }
        try keychain.saveToken(trimmedToken)
        self.token = trimmedToken
        tokenStore.setToken(trimmedToken)
    }

    func signOut() throws {
        try keychain.deleteToken()
        token = nil
        tokenStore.setToken(nil)
    }
}
