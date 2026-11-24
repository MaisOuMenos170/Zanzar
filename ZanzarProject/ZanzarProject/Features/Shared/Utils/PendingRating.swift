import CoreLocation
import Foundation

/// A check-in the user has not rated yet. Persisted locally so the map can ask for a rating
/// once the user has moved away from the place.
struct PendingRating: Codable, Hashable, Sendable {
    let userID: String
    let placeID: String
    let placeName: String
    let latitude: Double
    let longitude: Double
    let checkedInAt: Date
    /// Localization key of the place's category, shown as a chip in the rating sheet. `nil` for records saved
    /// before it was kept.
    var categoryTitleKey: String?

    func isExpired(now: Date, window: TimeInterval) -> Bool {
        now.timeIntervalSince(checkedInAt) > window
    }

    func hasLeft(userCoordinate: UserCoordinate, threshold: CLLocationDistance) -> Bool {
        let place = CLLocation(latitude: latitude, longitude: longitude)
        let user = CLLocation(latitude: userCoordinate.latitude, longitude: userCoordinate.longitude)
        return user.distance(from: place) > threshold
    }
}
