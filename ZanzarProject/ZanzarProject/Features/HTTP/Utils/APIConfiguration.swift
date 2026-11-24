import Foundation

nonisolated enum APIConfiguration {
    private static let bundleKey = "ZanzarAPIBaseURL"

    static var baseURL: URL {
        guard
            let rawValue = Bundle.main.object(forInfoDictionaryKey: bundleKey) as? String,
            let url = URL(string: rawValue),
            !rawValue.isEmpty
        else {
            #if DEBUG
            return URL(string: "http://127.0.0.1:3000")!
            #else
            preconditionFailure("ZanzarAPIBaseURL must be configured for Release builds.")
            #endif
        }
        #if !DEBUG
        precondition(url.scheme == "https", "ZanzarAPIBaseURL must be an https URL for Release builds.")
        #endif
        return url
    }
}
