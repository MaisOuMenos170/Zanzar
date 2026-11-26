import CoreLocation
import Foundation

protocol LocationMapServicing: Sendable {
    func currentUserLocation() async throws -> UserCoordinate
    func fetchNearbyPlaces(from coordinate: UserCoordinate) async throws -> [MapPlace]
}

// The project's default actor isolation is MainActor, so this class (and its
// CLLocationManager) is implicitly MainActor-isolated and therefore Sendable.
final class LocationMapService: LocationMapServicing {
    static let shared = LocationMapService()

    private let manager = CLLocationManager()
    private let client: NetworkClient

    init(client: NetworkClient = URLSessionNetworkClient.shared) {
        self.client = client
    }

    /// No fix after this long (no signal, location unavailable) counts as "no location", so a screen waiting
    /// for it can carry on without one.
    private static let locationTimeout: Duration = .seconds(10)

    func currentUserLocation() async throws -> UserCoordinate {
        #if DEBUG && targetEnvironment(simulator)
        if DevLocation.isFixed { return DevLocation.historicCenter }
        #endif
        if manager.authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }

        return try await withTimeout(Self.locationTimeout, throwing: LocationMapError.locationUnavailable) {
            try await self.firstLocationUpdate()
        }
    }

    private func firstLocationUpdate() async throws -> UserCoordinate {
        for try await update in CLLocationUpdate.liveUpdates() {
            if update.authorizationDenied || update.authorizationRestricted {
                AppLog.map.warning("Location authorization denied or restricted")
                throw LocationMapError.authorizationDenied
            }
            if let location = update.location {
                return UserCoordinate(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude,
                    accuracyMeters: location.horizontalAccuracy
                )
            }
        }
        AppLog.map.error("Location updates ended without a location", error: LocationMapError.locationUnavailable)
        throw LocationMapError.locationUnavailable
    }

    func fetchNearbyPlaces(from coordinate: UserCoordinate) async throws -> [MapPlace] {
        AppLog.map.info("Fetching nearby places...")
        do {
            let responses: [PlaceAPIResponse] = try await client.get(
                path: "places",
                queryItems: [
                    URLQueryItem(name: "lat", value: String(coordinate.latitude)),
                    URLQueryItem(name: "lng", value: String(coordinate.longitude))
                ]
            )
            AppLog.map.info("Fetched \(responses.count) nearby places successfully")
            return responses.map(MapPlace.init(response:))
        } catch {
            AppLog.map.error("Failed to fetch nearby places", error: error)
            throw error
        }
    }
}
