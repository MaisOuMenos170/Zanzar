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
    /// The full-size photo, when the backend sends one.
    let imageURL: URL?
    let decisionReason: UserPhotoDecisionReason?
    let createdAt: Date
    let decidedAt: Date?

    /// What the viewer opens: the full-size photo, or the thumbnail when that is all there is.
    var viewerURL: URL? { imageURL ?? thumbnailURL }
}
