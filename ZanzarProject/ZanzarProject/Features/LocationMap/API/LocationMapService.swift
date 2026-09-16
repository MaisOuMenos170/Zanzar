import CoreLocation

enum LocationMapError: Error, Sendable {
    case authorizationDenied
    case locationUnavailable
}

protocol LocationMapServicing: Sendable {
    func currentUserLocation() async throws -> UserCoordinate
}

// The project's default actor isolation is MainActor, so this class (and its
// CLLocationManager) is implicitly MainActor-isolated and therefore Sendable.
final class LocationMapService: LocationMapServicing {
    private let manager = CLLocationManager()

    func currentUserLocation() async throws -> UserCoordinate {
        if manager.authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }

        for try await update in CLLocationUpdate.liveUpdates() {
            if update.authorizationDenied || update.authorizationRestricted {
                throw LocationMapError.authorizationDenied
            }
            if let location = update.location {
                return UserCoordinate(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
            }
        }
        throw LocationMapError.locationUnavailable
    }
}
