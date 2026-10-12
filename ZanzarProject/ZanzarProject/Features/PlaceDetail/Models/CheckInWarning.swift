import Foundation

/// Why a check-in stopped before it was saved.
enum CheckInWarning: Equatable, Sendable {
    case tooFar
    case locationRequired
    case locationUncertain
}
