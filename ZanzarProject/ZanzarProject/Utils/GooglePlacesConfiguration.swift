import Foundation

nonisolated enum GooglePlacesConfiguration {
    static func photoURL(reference: String, maxWidth: Int = 800) -> URL? {
        var components = URLComponents(
            url: APIConfiguration.baseURL.appending(path: "places/photo"),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [
            URLQueryItem(name: "ref", value: reference),
            URLQueryItem(name: "maxwidth", value: String(maxWidth))
        ]
        return components?.url
    }
}
