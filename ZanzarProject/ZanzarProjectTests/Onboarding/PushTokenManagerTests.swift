import Foundation
import Testing
@testable import ZanzarProject

@MainActor
@Suite("PushTokenManager")
struct PushTokenManagerTests {
    private final class RecordingClient: NetworkClient, @unchecked Sendable {
        private(set) var registeredPaths: [String] = []
        var failure: Error?

        func get<Response: Decodable>(path: String, queryItems: [URLQueryItem]) async throws -> Response {
            throw APIError.invalidRequest
        }

        func send<Body: Encodable, Response: Decodable>(
            path: String,
            method: HTTPMethod,
            body: Body
        ) async throws -> Response {
            throw APIError.invalidRequest
        }

        func sendWithoutResponse(path: String, method: HTTPMethod) async throws {}

        func sendWithoutResponse<Body: Encodable>(path: String, method: HTTPMethod, body: Body) async throws {
            if let failure { throw failure }
            registeredPaths.append(path)
        }
    }

    private struct Harness {
        let manager: PushTokenManager
        let client: RecordingClient
        let tokenStore: AuthTokenStore
    }

    private func makeHarness() throws -> Harness {
        let defaults = try #require(UserDefaults(suiteName: "PushTokenManagerTests-\(UUID().uuidString)"))
        let client = RecordingClient()
        let tokenStore = AuthTokenStore()
        return Harness(
            manager: PushTokenManager(client: client, defaults: defaults, tokenStore: tokenStore),
            client: client,
            tokenStore: tokenStore
        )
    }

    private func signIn(_ userID: String, in tokenStore: AuthTokenStore) throws {
        let payload = Data(#"{"id":"\#(userID)"}"#.utf8).base64EncodedString()
            .replacingOccurrences(of: "=", with: "")
        let tokens = try #require(AuthTokens(accessToken: "h.\(payload).s", refreshToken: "refresh-\(userID)"))
        tokenStore.setTokens(tokens)
    }

    private let deviceToken = Data([0xAB, 0xCD])

    @Test("a token received while signed in is registered for that user")
    func registersForTheSignedInUser() async throws {
        let harness = try makeHarness()
        try signIn("user-a", in: harness.tokenStore)

        await harness.manager.register(deviceToken: deviceToken)

        #expect(harness.client.registeredPaths == ["user/user-a/device-token"])
        #expect(harness.manager.storedToken == "abcd")
    }

    @Test("sendIfNeeded does not send the same token twice for the same session")
    func doesNotResend() async throws {
        let harness = try makeHarness()
        try signIn("user-a", in: harness.tokenStore)
        await harness.manager.register(deviceToken: deviceToken)

        await harness.manager.sendIfNeeded()

        #expect(harness.client.registeredPaths.count == 1)
    }

    @Test("another account signing in on the same phone registers the token again")
    func nextAccountRegistersTheToken() async throws {
        let harness = try makeHarness()
        try signIn("user-a", in: harness.tokenStore)
        await harness.manager.register(deviceToken: deviceToken)

        // Sign out (ContentView forgets the sent flag), then another account signs in. iOS hands out the same token.
        harness.tokenStore.setTokens(nil)
        harness.manager.forgetSentToken()
        try signIn("user-b", in: harness.tokenStore)
        await harness.manager.register(deviceToken: deviceToken)
        await harness.manager.sendIfNeeded()

        #expect(harness.client.registeredPaths == ["user/user-a/device-token", "user/user-b/device-token"])
    }

    @Test("a failed registration is tried again on the next sendIfNeeded")
    func failedRegistrationIsRetried() async throws {
        let harness = try makeHarness()
        try signIn("user-a", in: harness.tokenStore)
        harness.client.failure = URLError(.notConnectedToInternet)
        await harness.manager.register(deviceToken: deviceToken)
        #expect(harness.client.registeredPaths.isEmpty)

        harness.client.failure = nil
        await harness.manager.sendIfNeeded()

        #expect(harness.client.registeredPaths == ["user/user-a/device-token"])
    }
}
