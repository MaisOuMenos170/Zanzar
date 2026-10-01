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
        AppLog.auth.info("Session restored from keychain")
    }

    func signIn(token: String) throws {
        let trimmedToken = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedToken.isEmpty else {
            AppLog.auth.error("Sign in rejected: empty token", error: AuthSessionError.invalidToken)
            throw AuthSessionError.invalidToken
        }
        do {
            try keychain.saveToken(trimmedToken)
        } catch {
            AppLog.auth.error("Failed to save token to keychain", error: error)
            throw error
        }
        self.token = trimmedToken
        tokenStore.setToken(trimmedToken)
        AppLog.auth.info("Signed in, token saved to keychain")
    }

    func signOut() throws {
        do {
            try keychain.deleteToken()
        } catch {
            AppLog.auth.error("Failed to delete token from keychain", error: error)
            throw error
        }
        token = nil
        tokenStore.setToken(nil)
        AppLog.auth.info("Signed out")
    }
}
