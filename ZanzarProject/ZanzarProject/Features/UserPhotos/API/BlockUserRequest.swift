import Foundation

/// Body of `POST /user/{id}/blocks`: blocks the author of a photo without the app knowing who it is.
nonisolated struct BlockUserRequest: Encodable, Sendable {
    let photoId: String
}
