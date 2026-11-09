import Foundation

/// Body of `GET /user/{id}/blocks`.
nonisolated struct BlockedUsersAPIResponse: Decodable, Sendable {
    let blockedUsers: [FailableDecodable<BlockedUserAPIResponse>]
}
