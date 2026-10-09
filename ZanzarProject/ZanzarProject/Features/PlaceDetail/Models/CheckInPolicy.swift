import CoreLocation

/// How close someone has to be before a check-in is allowed.
/// Matches the backend `CHECKIN_RADIUS_METERS` default.
enum CheckInPolicy {
    static let maximumDistance: CLLocationDistance = 150

    enum Verdict: Equatable, Sendable {
        case allowed
        case tooFar
        case uncertain
    }

    static func verdict(
        for user: UserCoordinate,
        placeLatitude: Double,
        placeLongitude: Double
    ) -> Verdict {
        if let accuracy = user.accuracyMeters, accuracy < 0 || accuracy > maximumDistance {
            return .uncertain
        }

        let distance = CLLocation(latitude: user.latitude, longitude: user.longitude)
            .distance(from: CLLocation(latitude: placeLatitude, longitude: placeLongitude))
        return distance > maximumDistance ? .tooFar : .allowed
    }
}
