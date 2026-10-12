import CoreLocation
import Foundation

nonisolated enum RatingPromptPolicy {
    /// How far from the place the user must be before we consider they have left it.
    static let leaveDistance: CLLocationDistance = 150
    /// How long after the check-in we are still willing to ask for a rating.
    static let validityWindow: TimeInterval = 6 * 60 * 60
    /// How often we re-check the user's location while a rating is pending and the map is visible.
    static let pollInterval: Duration = .seconds(30)
}
