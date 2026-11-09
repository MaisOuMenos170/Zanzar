import Foundation

/// Where a photo sent by a user stands. Only `approved` photos are shown to other people.
nonisolated enum UserPhotoStatus: String, Sendable, Hashable, Decodable {
    case pending
    case approved
    case rejected
    case needsReview = "needs_review"
    case removed

    /// Still waiting for the automatic or the human review.
    var isUnderReview: Bool {
        self == .pending || self == .needsReview
    }
}
