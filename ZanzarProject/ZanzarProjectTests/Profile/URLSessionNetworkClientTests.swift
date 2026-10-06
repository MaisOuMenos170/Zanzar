import Foundation
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

    @Test("maps a non-2xx response to an API error")
    func mapsHTTPFailure() async {
        StubURLProtocol.stub(status: 401, body: Data(#"{"message":"Invalid JWT token"}"#.utf8))

        await #expect(throws: APIError.self) {
            try await makeClient().sendWithoutResponse(path: "logout", method: .post)
        }
    }
}

nonisolated final class StubURLProtocol: URLProtocol, @unchecked Sendable {
    private static let lock = NSLock()
    private static var status = 204
    private static var body = Data()
    private static var recordedRequest: URLRequest?

    static var lastRequest: URLRequest? {
        lock.withLock { recordedRequest }
    }

    static func stub(status: Int, body: Data = Data()) {
        lock.withLock {
            self.status = status
            self.body = body
            recordedRequest = nil
        }
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let (status, body) = Self.lock.withLock {
            Self.recordedRequest = request
            return (Self.status, Self.body)
        }
        let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: body)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
