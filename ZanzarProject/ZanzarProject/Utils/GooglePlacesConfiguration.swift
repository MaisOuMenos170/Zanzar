import Foundation

enum GooglePlacesConfiguration {
    private static let bundleKey = "GooglePlacesAPIKey"

    /// Chave compartilhada com o projeto CacheGoogleMaps (Google Places Photo API).
    static var apiKey: String? {
        guard
            let rawValue = Bundle.main.object(forInfoDictionaryKey: bundleKey) as? String,
            !rawValue.isEmpty
        else {
            return nil
        }
        return rawValue
    }

    static func photoURL(reference: String, maxWidth: Int = 800) -> URL? {
        guard let apiKey else { return nil }
        var components = URLComponents(string: "https://maps.googleapis.com/maps/api/place/photo")
        components?.queryItems = [
            URLQueryItem(name: "maxwidth", value: String(maxWidth)),
            URLQueryItem(name: "photoreference", value: reference),
            URLQueryItem(name: "key", value: apiKey),
        ]
        return components?.url
    }
}
