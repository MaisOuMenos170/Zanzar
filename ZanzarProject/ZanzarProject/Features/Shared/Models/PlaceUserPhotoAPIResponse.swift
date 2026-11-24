import Foundation

/// An entry of `GET /places/{placeId}/photos`: an approved photo, or one of the signed-in user's own photos
/// still under review (then `url` is a signed link that expires).
nonisolated struct PlaceUserPhotoAPIResponse: Decodable, Sendable {
    let id: String
    let status: UserPhotoStatus
    let url: String?
    let thumbnailUrl: String?
    let isVerifiedCheckIn: Bool
    let authorName: String?
    let isOwn: Bool

    /// The carousel photo, or `nil` when it has no usable URL or is not something the carousel shows
    /// (a rejected or removed photo lives only in "My photos").
    var photo: PlacePhoto? {
        guard status == .approved || (isOwn && status.isUnderReview) else { return nil }
        guard let url = url.flatMap(Self.allowedURL) else { return nil }
        return PlacePhoto(
            url: url,
            credit: nil,
            userAttribution: UserPhotoAttribution(
                photoID: id,
                authorName: authorName,
                isVerifiedCheckIn: isVerifiedCheckIn,
                isOwn: isOwn,
                status: status
            )
        )
    }

    /// `https` only, except that Debug builds also accept the local backend's `http` file server.
    static func allowedURL(_ string: String) -> URL? {
        guard let url = URL(string: string) else { return nil }
        switch url.scheme?.lowercased() {
        case "https":
            return url
        #if DEBUG
        case "http" where url.host() == "127.0.0.1" || url.host() == "localhost":
            return url
        #endif
        default:
            return nil
        }
    }
}
