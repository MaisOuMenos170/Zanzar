import CoreLocation
import Foundation

enum RatingPromptPolicy {
    /// How far from the place the user must be before we consider they have left it.
    static let leaveDistance: CLLocationDistance = 150
    /// How long after the check-in we are still willing to ask for a rating.
    static let validityWindow: TimeInterval = 6 * 60 * 60
}
