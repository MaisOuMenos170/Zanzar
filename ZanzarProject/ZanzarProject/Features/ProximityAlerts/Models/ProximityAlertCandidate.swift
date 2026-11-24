import Foundation

/// A place the user just came close to, and what the policy needs to know to decide whether to tell them.
nonisolated struct ProximityAlertCandidate: Hashable, Sendable {
    nonisolated enum Kind: Hashable, Sendable {
        /// Any place of the app the user passes by.
        case nearbyPlace
        /// The next pending stop of the roteiro the user is following; `runID` tells one run from the next.
        case itineraryStop(runID: String)
    }

    let placeID: String
    let kind: Kind
    /// `nil` when the backend has no hours for the place; that is "unknown", never "closed".
    let openingHours: OpeningHours?
    let hasCheckedIn: Bool
}
