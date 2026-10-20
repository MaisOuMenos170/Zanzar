import Foundation
import os

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

protocol NetworkClient: Sendable {
    func get<Response: Decodable>(path: String, queryItems: [URLQueryItem]) async throws -> Response
    func send<Body: Encodable, Response: Decodable>(
        path: String,
        method: HTTPMethod,
        body: Body
    ) async throws -> Response
    /// For endpoints that answer with an empty body (e.g. `204 No Content`) and take no payload.
    func sendWithoutResponse(path: String, method: HTTPMethod) async throws
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

    // `/places` is intentionally omitted: the backend accepts anonymous reads but enriches
    // responses when a Bearer token is available (optional auth).
    private static let publicPaths: Set<String> = ["login", "register", "health"]

    private let baseURL: URL
    private let session: URLSession
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    private let authTokenProvider: @Sendable () -> String?
    private let now: @Sendable () -> Date
    /// End of the `Retry-After` window of the last 429. While it lies in the future no request leaves the device.
    private let blockedUntil = OSAllocatedUnfairLock<Date?>(initialState: nil)

    /// Used when a 429 carries no usable `Retry-After`.
    static let defaultRetryAfter: TimeInterval = 60
    private static let retryAfterRange: ClosedRange<TimeInterval> = 1...3600

    init(
        baseURL: URL,
        session: URLSession = .shared,
        authTokenProvider: @escaping @Sendable () -> String? = { nil },
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.baseURL = baseURL
        self.session = session
        self.authTokenProvider = authTokenProvider
        self.now = now
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

    func sendWithoutResponse(path: String, method: HTTPMethod) async throws {
        let normalizedPath = normalizedPath(path)
        guard let url = buildURL(path: normalizedPath, queryItems: []) else {
            throw APIError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        let (_, summary) = try await performRequest(authorizedRequest(from: request, path: normalizedPath))
        AppLog.network.info(summary)
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

    /// Hides the user id in `/user/{id}/...` so device logs never carry it.
    static func redactedPath(_ path: String) -> String {
        var previous = ""
        return path.split(separator: "/", omittingEmptySubsequences: false)
            .map { segment in
                defer { previous = String(segment) }
                return previous == "user" ? "*" : String(segment)
            }
            .joined(separator: "/")
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
        let (data, summary) = try await performRequest(request)
        do {
            let decoded = try decoder.decode(Response.self, from: data)
            AppLog.network.info(summary)
            return decoded
        } catch {
            AppLog.network.error("\(summary) | decoding failed, body=\(data.count) bytes", error: error)
            throw APIError.decodingFailed
        }
    }

    /// Runs the request and validates the status; returns the raw body plus a log summary line.
    private func performRequest(_ request: URLRequest) async throws -> (data: Data, summary: String) {
        let label = "\(request.httpMethod ?? "?") \(Self.redactedPath(request.url?.path ?? "?"))"
        try failIfRateLimited(label: label)
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

        if status == 429 {
            let current = now()
            let retryAfter = Self.retryAfter(from: httpResponse, now: current)
            let until = current.addingTimeInterval(retryAfter)
            blockedUntil.withLock { $0 = until }
            AppLog.network.warning("\(summary) | rate limited, holding requests for \(Int(retryAfter))s")
            throw APIError.rateLimited(retryAfter: retryAfter)
        }

        guard (200..<300).contains(status) else {
            let apiError = APIError.from(data: data, statusCode: status)
            if status >= 500 {
                AppLog.network.error(summary, error: apiError)
            } else {
                AppLog.network.warning(summary)
            }
            throw apiError
        }

        return (data, summary)
    }

    /// Fails fast, without touching the network, while the window of an earlier 429 is still open.
    private func failIfRateLimited(label: String) throws {
        let current = now()
        let remaining: TimeInterval? = blockedUntil.withLock { blocked in
            guard let until = blocked else { return nil }
            let remaining = until.timeIntervalSince(current)
            if remaining > 0 { return remaining }
            blocked = nil
            return nil
        }
        guard let remaining else { return }
        AppLog.network.info("\(label) skipped, rate limited for \(Int(remaining.rounded(.up)))s more")
        throw APIError.rateLimited(retryAfter: remaining)
    }

    /// Seconds to wait after a 429: `Retry-After` (delta-seconds or HTTP date), else `RateLimit-Reset`
    /// (delta-seconds), else `defaultRetryAfter`; clamped so a bad header can't lock the app for long.
    static func retryAfter(from response: HTTPURLResponse, now: Date) -> TimeInterval {
        let seconds: TimeInterval
        if let value = response.value(forHTTPHeaderField: "Retry-After")?.trimmingCharacters(in: .whitespaces),
           let parsed = TimeInterval(value) ?? httpDate(value).map({ $0.timeIntervalSince(now) }) {
            seconds = parsed
        } else if let value = response.value(forHTTPHeaderField: "RateLimit-Reset"),
                  let parsed = TimeInterval(value.trimmingCharacters(in: .whitespaces)) {
            seconds = parsed
        } else {
            seconds = defaultRetryAfter
        }
        return min(max(seconds, retryAfterRange.lowerBound), retryAfterRange.upperBound)
    }

    private static func httpDate(_ value: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "GMT")
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
        return formatter.date(from: value)
    }
}
