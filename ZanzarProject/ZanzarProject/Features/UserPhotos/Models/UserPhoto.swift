import Foundation

/// One of the signed-in user's own photos, as "My photos" lists it.
nonisolated struct UserPhoto: Identifiable, Hashable, Sendable {
    let id: String
    let placeID: String
    let placeName: String?
    let status: UserPhotoStatus
    let isVerifiedCheckIn: Bool
    let showsAuthorName: Bool
    let thumbnailURL: URL?
    let decisionReason: UserPhotoDecisionReason?
    let createdAt: Date
    let decidedAt: Date?
}
