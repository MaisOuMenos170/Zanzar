import Foundation
import os
import Testing
@testable import ZanzarProject

/// Serialized: `RoutedURLProtocol` keeps its handler and request log in static state.
@MainActor
@Suite("Session refresh", .serialized)
struct SessionRefreshTests {
    private struct Harness {
        let client: URLSessionNetworkClient
        let persistence: InMemoryAuthTokenStore
        let tokenStore: AuthTokenStore
        let expiredCount: OSAllocatedUnfairLock<Int>
    }

    private nonisolated static let refreshedBody = Data(#"{"token":"new-access","refreshToken":"new-refresh"}"#.utf8)

    private func makeHarness(signedIn: Bool = true) throws -> Harness {
        let persistence = InMemoryAuthTokenStore()
        let tokenStore = AuthTokenStore()
        if signedIn {
            let tokens = try #require(AuthTokens(accessToken: "old-access", refreshToken: "old-refresh"))
            try persistence.saveTokens(tokens)
            tokenStore.setTokens(tokens)
        }
        let expiredCount = OSAllocatedUnfairLock(initialState: 0)

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [RoutedURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let baseURL = URL(string: "https://api.example.com")!

        let refresher = SessionRefresher(
            baseURL: baseURL,
            session: session,
            persistence: persistence,
            tokenStore: tokenStore,
            onSessionExpired: { expiredCount.withLock { $0 += 1 } }
        )
        let client = URLSessionNetworkClient(
            baseURL: baseURL,
            session: session,
            authTokenProvider: { tokenStore.getToken() },
            refresher: refresher
        )
        return Harness(client: client, persistence: persistence, tokenStore: tokenStore, expiredCount: expiredCount)
    }

    private func routeProtectedRequestsToNewToken(refreshStatus: Int = 200, refreshBody: Data = refreshedBody) {
        RoutedURLProtocol.install { request in
            switch request.url?.path {
            case "/refresh":
                return .init(status: refreshStatus, body: refreshBody)
            default:
                let authorized = request.value(forHTTPHeaderField: "Authorization") == "Bearer new-access"
                return authorized
                    ? .init(status: 200, body: Data(#"["ok"]"#.utf8))
                    : .init(status: 401, body: Data(#"{"success":false,"message":"Invalid JWT token"}"#.utf8))
            }
        }
    }

    @Test("a 401 refreshes the tokens and replays the request with the new access token")
    func refreshesAndReplays() async throws {
        let harness = try makeHarness()
        routeProtectedRequestsToNewToken()

        let result: [String] = try await harness.client.get(path: "itineraries")

        #expect(result == ["ok"])
        #expect(RoutedURLProtocol.paths == ["/itineraries", "/refresh", "/itineraries"])
        #expect(harness.tokenStore.getToken() == "new-access")
        #expect(harness.tokenStore.getRefreshToken() == "new-refresh")
        let persisted = try #require(harness.persistence.readTokens())
        #expect(persisted.accessToken == "new-access")
        #expect(persisted.refreshToken == "new-refresh")
        #expect(harness.expiredCount.withLock { $0 } == 0)
    }

    @Test("the refresh request carries the refresh token in the body and no Authorization header")
    func refreshRequestShape() async throws {
        let harness = try makeHarness()
        routeProtectedRequestsToNewToken()

        let _: [String] = try await harness.client.get(path: "itineraries")

        let refresh = try #require(RoutedURLProtocol.requests.first { $0.url?.path == "/refresh" })
        #expect(refresh.httpMethod == "POST")
        #expect(refresh.value(forHTTPHeaderField: "Authorization") == nil)
        let body = try #require(RoutedURLProtocol.bodies["/refresh"])
        let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: String])
        #expect(json == ["refreshToken": "old-refresh"])
    }

    @Test("concurrent 401s share a single refresh call")
    func concurrentRequestsRefreshOnce() async throws {
        let harness = try makeHarness()
        routeProtectedRequestsToNewToken()
        RoutedURLProtocol.responseDelay = .milliseconds(50)

        try await withThrowingTaskGroup(of: [String].self) { group in
            for path in ["itineraries", "places", "rating"] {
                group.addTask { try await harness.client.get(path: path) }
            }
            for try await result in group {
                #expect(result == ["ok"])
            }
        }

        #expect(RoutedURLProtocol.paths.filter { $0 == "/refresh" }.count == 1)
        #expect(harness.tokenStore.getToken() == "new-access")
    }

    @Test("a rejected refresh token ends the session and clears the stored tokens")
    func rejectedRefreshExpiresTheSession() async throws {
        let harness = try makeHarness()
        routeProtectedRequestsToNewToken(
            refreshStatus: 401,
            refreshBody: Data(#"{"success":false,"message":"Invalid refresh token"}"#.utf8)
        )

        await #expect(throws: APIError.self) {
            let _: [String] = try await harness.client.get(path: "itineraries")
        }

        #expect(harness.expiredCount.withLock { $0 } == 1)
        #expect(harness.tokenStore.getToken() == nil)
        #expect(harness.tokenStore.getRefreshToken() == nil)
        #expect(harness.persistence.readTokens() == nil)
    }

    @Test("a refresh that fails with 5xx keeps the session")
    func serverErrorKeepsTheSession() async throws {
        let harness = try makeHarness()
        routeProtectedRequestsToNewToken(refreshStatus: 503, refreshBody: Data())

        do {
            let _: [String] = try await harness.client.get(path: "itineraries")
            Issue.record("Expected the refresh failure to surface")
        } catch let APIError.httpStatus(status, _) {
            #expect(status == 503)
        }

        #expect(harness.expiredCount.withLock { $0 } == 0)
        #expect(harness.tokenStore.getToken() == "old-access")
        #expect(harness.tokenStore.getRefreshToken() == "old-refresh")
        #expect(harness.persistence.readTokens() != nil)
    }

    @Test("a refresh that is rate limited keeps the session")
    func rateLimitedRefreshKeepsTheSession() async throws {
        let harness = try makeHarness()
        routeProtectedRequestsToNewToken(refreshStatus: 429, refreshBody: Data())

        do {
            let _: [String] = try await harness.client.get(path: "itineraries")
            Issue.record("Expected a rate limit error")
        } catch APIError.rateLimited {}

        #expect(harness.expiredCount.withLock { $0 } == 0)
        #expect(harness.tokenStore.getRefreshToken() == "old-refresh")
    }

    @Test("a refresh that cannot reach the server keeps the session")
    func transportFailureKeepsTheSession() async throws {
        let harness = try makeHarness()
        RoutedURLProtocol.install { request in
            request.url?.path == "/refresh"
                ? .init(failure: URLError(.notConnectedToInternet))
                : .init(status: 401, body: Data())
        }

        await #expect(throws: URLError.self) {
            let _: [String] = try await harness.client.get(path: "itineraries")
        }

        #expect(harness.expiredCount.withLock { $0 } == 0)
        #expect(harness.tokenStore.getRefreshToken() == "old-refresh")
    }

    @Test("a 401 on the replay after a successful refresh ends the session, without a third attempt")
    func rejectedReplayExpiresTheSession() async throws {
        let harness = try makeHarness()
        RoutedURLProtocol.install { request in
            request.url?.path == "/refresh"
                ? .init(status: 200, body: Self.refreshedBody)
                : .init(status: 401, body: Data())
        }

        await #expect(throws: APIError.self) {
            let _: [String] = try await harness.client.get(path: "itineraries")
        }

        #expect(RoutedURLProtocol.paths == ["/itineraries", "/refresh", "/itineraries"])
        #expect(harness.expiredCount.withLock { $0 } == 1)
        #expect(harness.tokenStore.getToken() == nil)
        #expect(harness.persistence.readTokens() == nil)
    }

    @Test("401s from login and logout never trigger a refresh")
    func authPathsDoNotRefresh() async throws {
        let harness = try makeHarness()
        RoutedURLProtocol.install { _ in .init(status: 401, body: Data()) }

        await #expect(throws: APIError.self) {
            let _: LoginResponse = try await harness.client.send(
                path: "login",
                method: .post,
                body: LoginRequest(email: "ana@example.com", password: "secret12")
            )
        }
        await #expect(throws: APIError.self) {
            try await harness.client.sendWithoutResponse(path: "logout", method: .post)
        }

        #expect(RoutedURLProtocol.paths == ["/login", "/logout"])
        #expect(harness.expiredCount.withLock { $0 } == 0)
        #expect(harness.tokenStore.getRefreshToken() == "old-refresh")
    }

    @Test("a 401 with no stored session does not alert or refresh")
    func signedOutRequestDoesNotExpire() async throws {
        let harness = try makeHarness(signedIn: false)
        RoutedURLProtocol.install { _ in .init(status: 401, body: Data()) }

        await #expect(throws: APIError.self) {
            let _: [String] = try await harness.client.get(path: "places")
        }

        #expect(RoutedURLProtocol.paths == ["/places"])
        #expect(harness.expiredCount.withLock { $0 } == 0)
    }
}

nonisolated final class RoutedURLProtocol: URLProtocol, @unchecked Sendable {
    struct Reply: Sendable {
        var status = 200
        var body = Data()
        var failure: URLError?

        init(status: Int, body: Data = Data()) {
            self.status = status
            self.body = body
        }

        init(failure: URLError) {
            self.failure = failure
        }
    }

    private struct State {
        var handler: (@Sendable (URLRequest) -> Reply)?
        var delay: Duration = .zero
        var requests: [URLRequest] = []
        var bodies: [String: Data] = [:]
    }

    private static let state = OSAllocatedUnfairLock(initialState: State())

    static func install(_ handler: @escaping @Sendable (URLRequest) -> Reply) {
        state.withLock { $0 = State(handler: handler) }
    }

    static var responseDelay: Duration {
        get { state.withLock { $0.delay } }
        set { state.withLock { $0.delay = newValue } }
    }

    static var requests: [URLRequest] { state.withLock { $0.requests } }
    static var paths: [String] { requests.compactMap { $0.url?.path } }
    static var bodies: [String: Data] { state.withLock { $0.bodies } }

    override static func canInit(with request: URLRequest) -> Bool { true }
    override static func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let body = request.httpBody ?? request.httpBodyStream.map(Self.readAll)
        let (handler, delay) = Self.state.withLock { state in
            state.requests.append(request)
            if let body, let path = request.url?.path {
                state.bodies[path] = body
            }
            return (state.handler, state.delay)
        }
        let reply = handler?(request) ?? Reply(status: 500)

        let deliver = { [self] in
            if let failure = reply.failure {
                client?.urlProtocol(self, didFailWithError: failure)
                return
            }
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: reply.status,
                httpVersion: nil,
                headerFields: nil
            )!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: reply.body)
            client?.urlProtocolDidFinishLoading(self)
        }

        if delay == .zero {
            deliver()
        } else {
            DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(Int(delay / .milliseconds(1)))) {
                deliver()
            }
        }
    }

    override func stopLoading() {}

    private static func readAll(_ stream: InputStream) -> Data {
        stream.open()
        defer { stream.close() }
        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 1024)
        while stream.hasBytesAvailable {
            let count = stream.read(&buffer, maxLength: buffer.count)
            if count <= 0 { break }
            data.append(buffer, count: count)
        }
        return data
    }
}
