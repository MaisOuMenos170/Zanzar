import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

protocol NetworkClient: Sendable {
    func get<Response: Decodable>(path: String, queryItems: [URLQueryItem]) async throws -> Response
    func send<Body: Encodable, Response: Decodable>(path: String, method: HTTPMethod, body: Body) async throws -> Response
}

extension NetworkClient {
    func get<Response: Decodable>(path: String, queryItems: [URLQueryItem] = []) async throws -> Response {
        try await get(path: path, queryItems: queryItems)
    }
}

final class URLSessionNetworkClient: NetworkClient, @unchecked Sendable {
    static let shared = URLSessionNetworkClient(
        baseURL: APIConfiguration.baseURL,
        authTokenProvider: { AuthTokenStore.shared.getToken() }
    )

    private static let publicPaths: Set<String> = ["login", "register", "health"]

    private let baseURL: URL
    private let session: URLSession
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    private let authTokenProvider: @Sendable () -> String?

    init(
        baseURL: URL,
        session: URLSession = .shared,
        authTokenProvider: @escaping @Sendable () -> String? = { nil }
    ) {
        self.baseURL = baseURL
        self.session = session
        self.authTokenProvider = authTokenProvider
    }

    func get<Response: Decodable>(path: String, queryItems: [URLQueryItem]) async throws -> Response {
        let normalizedPath = normalizedPath(path)
        guard let url = buildURL(path: normalizedPath, queryItems: queryItems) else {
            throw APIError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.get.rawValue
        return try await perform(authorizedRequest(from: request, path: normalizedPath))
    }

    func send<Body: Encodable, Response: Decodable>(
        path: String,
        method: HTTPMethod,
        body: Body
    ) async throws -> Response {
        let normalizedPath = normalizedPath(path)
        guard let url = buildURL(path: normalizedPath, queryItems: []) else {
            throw APIError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(body)
        return try await perform(authorizedRequest(from: request, path: normalizedPath))
    }

    private func normalizedPath(_ path: String) -> String {
        path.hasPrefix("/") ? String(path.dropFirst()) : path
    }

    private func buildURL(path: String, queryItems: [URLQueryItem]) -> URL? {
        var url = baseURL
        for component in path.split(separator: "/") {
            url = url.appendingPathComponent(String(component))
        }
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.queryItems = queryItems.isEmpty ? nil : queryItems
        return components?.url
    }

    private func authorizedRequest(from request: URLRequest, path: String) -> URLRequest {
        var request = request
        guard !Self.publicPaths.contains(path) else { return request }
        if let token = authTokenProvider() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return request
    }

    private func perform<Response: Decodable>(_ request: URLRequest) async throws -> Response {
        let label = "\(request.httpMethod ?? "?") \(request.url?.path ?? "?")"
        let start = ContinuousClock.now
        AppLog.network.info("\(label) started")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            if !(error is CancellationError), (error as? URLError)?.code != .cancelled {
                AppLog.network.error("\(label) transport failure", error: error)
            }
            throw error
        }

        let elapsedMs = Int((ContinuousClock.now - start) / .milliseconds(1))
        guard let httpResponse = response as? HTTPURLResponse else {
            AppLog.network.error("\(label) returned a non-HTTP response (\(elapsedMs)ms)")
            throw APIError.invalidResponse
        }

        // Backend tags every request with an id; log it to find the matching server-side lines.
        let requestID = httpResponse.value(forHTTPHeaderField: "X-Request-Id") ?? "-"
        let status = httpResponse.statusCode
        let summary = "\(label) -> \(status) (\(elapsedMs)ms) reqId=\(requestID)"

        guard (200..<300).contains(status) else {
            let apiError = APIError.from(data: data, statusCode: status)
            if status >= 500 {
                AppLog.network.error(summary, error: apiError)
            } else {
                AppLog.network.warning(summary)
            }
            throw apiError
        }

        do {
            let decoded = try decoder.decode(Response.self, from: data)
            AppLog.network.info(summary)
            return decoded
        } catch {
            AppLog.network.error("\(summary) | decoding failed, body=\(data.count) bytes", error: error)
            throw APIError.decodingFailed
        }
    }
}
