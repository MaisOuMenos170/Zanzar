import Foundation

/// What the place screen needs to know about a photo that a user sent (as opposed to a curated one).
nonisolated struct UserPhotoAttribution: Hashable, Sendable {
    let photoID: String
    /// `nil` when the author chose to stay anonymous.
    let authorName: String?
    /// Sent together with a check-in at the place.
    let isVerifiedCheckIn: Bool
    /// The signed-in user sent it, so it may be shown while still under review.
    let isOwn: Bool
    let status: UserPhotoStatus
}

extension UserPhotoAttribution: Identifiable {
    var id: String { photoID }
}
