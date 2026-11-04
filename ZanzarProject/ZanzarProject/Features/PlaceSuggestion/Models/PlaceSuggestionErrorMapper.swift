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
        if case .httpStatus(400, _)? = error as? APIError {
            return L10n.string("placeSuggestion.error.invalid")
        }
        return L10n.string("placeSuggestion.error.generic")
    }
}
