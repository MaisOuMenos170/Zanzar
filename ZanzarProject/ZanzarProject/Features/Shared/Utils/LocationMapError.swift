import Foundation

enum LocationMapError: Error, Sendable {
    case authorizationDenied
    case locationUnavailable
}

extension LocationMapError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .authorizationDenied:
            L10n.string("locationMap.locationAccessDenied")
        case .locationUnavailable:
            L10n.string("locationMap.locationUnavailable")
        }
    }
}
