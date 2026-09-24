import Foundation

enum BackendConfiguration {
    /// Replace with the URL printed by `cloudflared tunnel --url http://127.0.0.1:8000`.
    /// For the iOS Simulator without a tunnel, use `http://127.0.0.1:8000`.
    static let baseURL = URL(string: "http://127.0.0.1:8000")!

    static var displayBaseURL: String {
        baseURL.absoluteString
    }
}
