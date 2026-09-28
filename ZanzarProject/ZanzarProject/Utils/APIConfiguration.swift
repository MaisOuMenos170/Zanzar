import Foundation

enum APIConfiguration {
    private static let bundleKey = "ZanzarAPIBaseURL"

    /// Cloudflare Tunnel URL for dev. Update with `./scripts/update-api-tunnel-url.sh`.
    private static let defaultBaseURL = URL(string: "https://invest-plaza-assessed-lived.trycloudflare.com")!

    static var baseURL: URL {
        guard
            let rawValue = Bundle.main.object(forInfoDictionaryKey: bundleKey) as? String,
            let url = URL(string: rawValue),
            !rawValue.isEmpty
        else {
            return defaultBaseURL
        }
        return url
    }
}
