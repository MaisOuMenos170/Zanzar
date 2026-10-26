import Foundation
import Observation

enum AuthSessionError: Error, Sendable {
    case invalidToken
}

@MainActor
@Observable
final class AuthSession {
    private(set) var isAuthenticated = false

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
        guard let tokens = keychain.readTokens() else {
            return
        }
        tokenStore.setTokens(tokens)
        isAuthenticated = true
        AppLog.auth.info("Session restored from keychain")
    }

    func signIn(accessToken: String, refreshToken: String) throws {
        guard let tokens = AuthTokens(accessToken: accessToken, refreshToken: refreshToken) else {
            AppLog.auth.error("Sign in rejected: empty token", error: AuthSessionError.invalidToken)
            throw AuthSessionError.invalidToken
        }
        do {
            try keychain.saveTokens(tokens)
        } catch {
            AppLog.auth.error("Failed to save tokens to keychain", error: error)
            throw error
        }
        tokenStore.setTokens(tokens)
        isAuthenticated = true
        AppLog.auth.info("Signed in, tokens saved to keychain")
    }

    func signOut() throws {
        do {
            try keychain.deleteTokens()
        } catch {
            AppLog.auth.error("Failed to delete tokens from keychain", error: error)
            throw error
        }
        tokenStore.setTokens(nil)
        isAuthenticated = false
        AppLog.auth.info("Signed out")
    }

    func handleSessionExpired() {
        isAuthenticated = false
    }
}
