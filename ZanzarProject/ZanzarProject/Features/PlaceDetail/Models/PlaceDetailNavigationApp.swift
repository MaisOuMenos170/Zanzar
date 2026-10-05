import UIKit

enum PlaceDetailNavigationApp: String, CaseIterable, Identifiable {
    case appleMaps
    case googleMaps
    case waze

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .appleMaps: "Apple Maps"
        case .googleMaps: "Google Maps"
        case .waze: "Waze"
        }
    }

    /// Apps currently installed. Each probe scheme must be declared in `LSApplicationQueriesSchemes`.
    @MainActor
    static var installed: [PlaceDetailNavigationApp] {
        allCases.filter { app in
            UIApplication.shared.canOpenURL(app.probeURL)
        }
    }

    func directionsURL(latitude: Double, longitude: Double, placeName: String) -> URL? {
        var components: URLComponents?
        switch self {
        case .appleMaps:
            components = URLComponents(string: "https://maps.apple.com/")
            components?.queryItems = [
                URLQueryItem(name: "daddr", value: "\(latitude),\(longitude)"),
                URLQueryItem(name: "q", value: placeName)
            ]
        case .googleMaps:
            components = URLComponents(string: "comgooglemaps://")
            components?.queryItems = [
                URLQueryItem(name: "daddr", value: "\(latitude),\(longitude)")
            ]
        case .waze:
            components = URLComponents(string: "waze://")
            components?.queryItems = [
                URLQueryItem(name: "ll", value: "\(latitude),\(longitude)"),
                URLQueryItem(name: "navigate", value: "yes")
            ]
        }
        return components?.url
    }

    private var probeURL: URL {
        switch self {
        case .appleMaps: URL(string: "maps://")!
        case .googleMaps: URL(string: "comgooglemaps://")!
        case .waze: URL(string: "waze://")!
        }
    }
}
