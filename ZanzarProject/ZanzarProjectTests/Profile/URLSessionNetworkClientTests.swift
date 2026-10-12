import Foundation
import os
import Testing
@testable import ZanzarProject

/// Serialized: the stub protocol shares one static response between tests.
@MainActor
@Suite("URLSessionNetworkClient.sendWithoutResponse", .serialized)
struct URLSessionNetworkClientTests {
    private func makeClient(token: String? = "token") -> URLSessionNetworkClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        return URLSessionNetworkClient(
            baseURL: URL(string: "https://api.example.com")!,
            session: URLSession(configuration: configuration),
            authTokenProvider: { token }
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
        var recordedRequest: URLRequest?
    }

    private static let state = OSAllocatedUnfairLock(initialState: State())

    static var lastRequest: URLRequest? {
        state.withLock { $0.recordedRequest }
    }

    static func stub(status: Int, body: Data = Data()) {
        state.withLock { state in
            state.status = status
            state.body = body
            state.recordedRequest = nil
        }
    }

    override static func canInit(with request: URLRequest) -> Bool { true }
    override static func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let (status, body) = Self.state.withLock { state in
            state.recordedRequest = request
            return (state.status, state.body)
        }
        let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: body)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
