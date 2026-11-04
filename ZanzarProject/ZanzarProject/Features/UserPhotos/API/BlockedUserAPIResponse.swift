import Foundation

nonisolated struct BlockedUserAPIResponse: Decodable, Sendable {
    let userId: String
    let username: String?

    var blockedUser: BlockedUser {
        BlockedUser(id: userId, username: username)
    }
}
