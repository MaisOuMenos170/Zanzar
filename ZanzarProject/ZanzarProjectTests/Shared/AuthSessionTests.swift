import Testing
@testable import ZanzarProject

@MainActor
@Suite("AuthSession")
struct AuthSessionTests {
    @Test("signIn stores both tokens and authenticates")
    func signInStoresBothTokens() throws {
        let persistence = InMemoryAuthTokenStore()
        let tokenStore = AuthTokenStore()
        let session = AuthSession(keychain: persistence, tokenStore: tokenStore)

        try session.signIn(accessToken: " access ", refreshToken: "refresh\n")

        #expect(session.isAuthenticated)
        #expect(tokenStore.getToken() == "access")
        #expect(tokenStore.getRefreshToken() == "refresh")
        #expect(persistence.readTokens() == AuthTokens(accessToken: "access", refreshToken: "refresh"))
    }

    @Test("signIn rejects a blank token")
    func signInRejectsBlankTokens() {
        let session = AuthSession(keychain: InMemoryAuthTokenStore(), tokenStore: AuthTokenStore())

        #expect(throws: AuthSessionError.self) {
            try session.signIn(accessToken: "access", refreshToken: "  ")
        }
        #expect(!session.isAuthenticated)
    }

    @Test("restore brings back a stored session")
    func restoreReadsStoredTokens() throws {
        let persistence = InMemoryAuthTokenStore()
        try persistence.saveTokens(try #require(AuthTokens(accessToken: "access", refreshToken: "refresh")))
        let tokenStore = AuthTokenStore()

        let session = AuthSession(keychain: persistence, tokenStore: tokenStore)

        #expect(session.isAuthenticated)
        #expect(tokenStore.getToken() == "access")
        #expect(tokenStore.getRefreshToken() == "refresh")
    }

    @Test("nothing is restored without stored tokens")
    func restoreWithoutTokens() {
        let session = AuthSession(keychain: InMemoryAuthTokenStore(), tokenStore: AuthTokenStore())

        #expect(!session.isAuthenticated)
    }

    @Test("handleSessionExpired signs the user out")
    func handleSessionExpired() throws {
        let session = AuthSession(keychain: InMemoryAuthTokenStore(), tokenStore: AuthTokenStore())
        try session.signIn(accessToken: "access", refreshToken: "refresh")

        session.handleSessionExpired()

        #expect(!session.isAuthenticated)
    }
}
