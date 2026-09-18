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
    static let shared = URLSessionNetworkClient(baseURL: URL(string: "https://api.example.com")!)

    private let baseURL: URL
    private let session: URLSession
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    func get<Response: Decodable>(path: String, queryItems: [URLQueryItem]) async throws -> Response {
        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)
        components?.queryItems = queryItems.isEmpty ? nil : queryItems
        guard let url = components?.url else { throw URLError(.badURL) }

        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.get.rawValue
        return try await perform(request)
    }

    func send<Body: Encodable, Response: Decodable>(path: String, method: HTTPMethod, body: Body) async throws -> Response {
        let url = baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(body)
        return try await perform(request)
    }

    private func perform<Response: Decodable>(_ request: URLRequest) async throws -> Response {
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try decoder.decode(Response.self, from: data)
    }
}
