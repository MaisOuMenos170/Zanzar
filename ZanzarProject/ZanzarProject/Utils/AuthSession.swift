import Foundation
import Observation

@MainActor
@Observable
final class AuthSession {
    private(set) var token: String?

    var isAuthenticated: Bool {
        token != nil
    }

    private let keychain: KeychainStore
    private let tokenStore: AuthTokenStore

    init(
        keychain: KeychainStore = KeychainStore(),
        tokenStore: AuthTokenStore = .shared
    ) {
        self.keychain = keychain
        self.tokenStore = tokenStore
    }

    func restore() {
        guard let storedToken = keychain.readToken() else {
            return
        }
        token = storedToken
        tokenStore.setToken(storedToken)
    }

    func signIn(token: String) throws {
        try keychain.saveToken(token)
        self.token = token
        tokenStore.setToken(token)
    }

    func signOut() {
        keychain.deleteToken()
        token = nil
        tokenStore.setToken(nil)
    }
}
