import Foundation

/// One page of the user's check-ins and where the next page starts.
nonisolated struct ProfileCheckInsPage: Hashable, Sendable {
    let checkIns: [ProfileCheckIn]
    /// The cursor to ask for the next page with; `nil` when this was the last one.
    let nextCursor: String?
}
