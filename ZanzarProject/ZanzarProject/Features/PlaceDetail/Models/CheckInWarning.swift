import Foundation

/// Why a check-in stopped before it was saved.
enum CheckInWarning: Equatable, Sendable {
    case tooFar
    case locationRequired
    case locationUncertain
    /// There is no network right now: the check-in can be kept and sent later.
    case offline
}
