import Foundation

nonisolated struct BlockedUser: Identifiable, Hashable, Sendable {
    let id: String
    /// `nil` when the account no longer exists.
    let username: String?
}
