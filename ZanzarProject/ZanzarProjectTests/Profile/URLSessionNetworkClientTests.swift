import Foundation
import os
import Testing
@testable import ZanzarProject

/// Serialized: the stub protocol shares one static response between tests.
@MainActor
@Suite("URLSessionNetworkClient.sendWithoutResponse", .serialized)
struct URLSessionNetworkClientTests {
    private func makeClient(token: String? = "token", clock: TestClock = TestClock()) -> URLSessionNetworkClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        return URLSessionNetworkClient(
            baseURL: URL(string: "https://api.example.com")!,
            session: URLSession(configuration: configuration),
            authTokenProvider: { token },
            now: { clock.date }
        )
    }

    @Test("accepts an empty 204 response and sends the Bearer token")
    func acceptsNoContent() async throws {
        StubURLProtocol.stub(status: 204)

        try await makeClient().sendWithoutResponse(path: "logout", method: .post)

        let request = try #require(StubURLProtocol.lastRequest)
        #expect(request.httpMethod == "POST")
        #expect(request.url?.path == "/logout")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer token")
    }

    @Test("log paths hide the user id")
    func redactsUserID() {
        #expect(URLSessionNetworkClient.redactedPath("/user/abc-123/profile") == "/user/*/profile")
        #expect(URLSessionNetworkClient.redactedPath("/logout") == "/logout")
    }

    @Test("a 429 holds every request until its Retry-After window ends, without reaching the server")
    func rateLimitBlocksRequestsUntilTheWindowEnds() async throws {
        let clock = TestClock()
        let client = makeClient(clock: clock)
        StubURLProtocol.stub(status: 429, headers: ["Retry-After": "120"])

        await #expect(throws: APIError.self) {
            try await client.sendWithoutResponse(path: "logout", method: .post)
        }
        #expect(StubURLProtocol.requestCount == 1)

        StubURLProtocol.stub(status: 204)
        clock.advance(by: 30)
        do {
            let _: [String] = try await client.get(path: "places")
            Issue.record("Expected the request to be blocked")
        } catch let APIError.rateLimited(retryAfter) {
            #expect(retryAfter == 90)
        }
        #expect(StubURLProtocol.requestCount == 0)

        clock.advance(by: 91)
        try await client.sendWithoutResponse(path: "logout", method: .post)
        #expect(StubURLProtocol.requestCount == 1)
    }

    @Test("a 429 without Retry-After holds requests for the default window")
    func rateLimitWithoutHeaderUsesTheDefault() async {
        let client = makeClient()
        StubURLProtocol.stub(status: 429)

        do {
            try await client.sendWithoutResponse(path: "logout", method: .post)
            Issue.record("Expected a rate limit error")
        } catch let APIError.rateLimited(retryAfter) {
            #expect(retryAfter == URLSessionNetworkClient.defaultRetryAfter)
        } catch {
            Issue.record("Unexpected error \(error)")
        }
    }

    @Test("Retry-After accepts seconds and HTTP dates, falls back to RateLimit-Reset, and is clamped")
    func parsesRetryAfter() throws {
        let url = try #require(URL(string: "https://api.example.com/places"))
        func response(_ headers: [String: String]) throws -> HTTPURLResponse {
            try #require(HTTPURLResponse(url: url, statusCode: 429, httpVersion: nil, headerFields: headers))
        }
        // Wed, 21 Oct 2015 07:28:00 GMT
        let now = Date(timeIntervalSince1970: 1_445_412_480)

        #expect(try URLSessionNetworkClient.retryAfter(from: response(["Retry-After": "45"]), now: now) == 45)
        #expect(
            try URLSessionNetworkClient.retryAfter(
                from: response(["Retry-After": "Wed, 21 Oct 2015 07:29:30 GMT"]),
                now: now
            ) == 90
        )
        #expect(try URLSessionNetworkClient.retryAfter(from: response(["RateLimit-Reset": "300"]), now: now) == 300)
        #expect(try URLSessionNetworkClient.retryAfter(from: response(["Retry-After": "0"]), now: now) == 1)
        #expect(try URLSessionNetworkClient.retryAfter(from: response(["Retry-After": "999999"]), now: now) == 3600)
        #expect(
            try URLSessionNetworkClient.retryAfter(from: response(["Retry-After": "soon"]), now: now)
                == URLSessionNetworkClient.defaultRetryAfter
        )
    }

    @Test("maps a non-2xx response to an API error")
    func mapsHTTPFailure() async {
        StubURLProtocol.stub(status: 401, body: Data(#"{"message":"Invalid JWT token"}"#.utf8))

        await #expect(throws: APIError.self) {
            try await makeClient().sendWithoutResponse(path: "logout", method: .post)
        }
    }
}

nonisolated final class StubURLProtocol: URLProtocol, @unchecked Sendable {
    private struct State: Sendable {
        var status = 204
        var body = Data()
        var headers: [String: String] = [:]
        var recordedRequest: URLRequest?
        var requestCount = 0
    }

    private static let state = OSAllocatedUnfairLock(initialState: State())

    static var lastRequest: URLRequest? {
        state.withLock { $0.recordedRequest }
    }

    /// Requests that reached the "server" since the last `stub(...)`.
    static var requestCount: Int {
        state.withLock { $0.requestCount }
    }

    static func stub(status: Int, body: Data = Data(), headers: [String: String] = [:]) {
        state.withLock { state in
            state.status = status
            state.body = body
            state.headers = headers
            state.recordedRequest = nil
            state.requestCount = 0
        }
    }

    override static func canInit(with request: URLRequest) -> Bool { true }
    override static func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let (status, body, headers) = Self.state.withLock { state in
            state.recordedRequest = request
            state.requestCount += 1
            return (state.status, state.body, state.headers)
        }
        let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: headers)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: body)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
