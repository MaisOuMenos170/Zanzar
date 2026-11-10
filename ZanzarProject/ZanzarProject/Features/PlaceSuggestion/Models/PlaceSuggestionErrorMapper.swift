import Foundation

enum PlaceSuggestionErrorMapper {
    static func isCancellation(_ error: Error) -> Bool {
        error is CancellationError || (error as? URLError)?.code == .cancelled
    }

    static func locationMessage(for error: Error) -> String {
        switch error as? LocationMapError {
        case .authorizationDenied:
            L10n.string("placeSuggestion.error.locationDenied")
        case .locationUnavailable, nil:
            L10n.string("placeSuggestion.error.locationUnavailable")
        }
    }

    static func submitMessage(for error: Error) -> String {
        if let locationError = error as? LocationMapError {
            return locationMessage(for: locationError)
        }
        if let rateLimited = APIError.rateLimitedMessage(for: error) {
            return rateLimited
        }
        switch error as? APIError {
        case .httpStatus(400, _)?:
            return L10n.string("placeSuggestion.error.invalid")
        case .rejected(404, "place_not_found", _)?:
            return L10n.string("placeSuggestion.error.notFound")
        case .rejected(503, "osm_unavailable", _)?:
            return L10n.string("placeSuggestion.error.osmUnavailable")
        default:
            return L10n.string("placeSuggestion.error.generic")
        }
    }

    static func searchMessage(for error: Error) -> String {
        if let rateLimited = APIError.rateLimitedMessage(for: error) {
            return rateLimited
        }
        if case .rejected(503, "osm_unavailable", _)? = error as? APIError {
            return L10n.string("placeSuggestion.error.osmUnavailable")
        }
        return L10n.string("placeSuggestion.error.search")
    }
}
