import Foundation

/// One of the signed-in user's photos, as `POST /places/{placeId}/photos` and `GET /user/{id}/photos` return it.
nonisolated struct UserPhotoAPIResponse: Decodable, Sendable {
    let id: String
    let placeId: String
    let placeName: String?
    let status: UserPhotoStatus
    let isVerifiedCheckIn: Bool
    let showAuthorName: Bool
    let url: String?
    let thumbnailUrl: String?
    let decisionReason: String?
    let createdAt: String
    let decidedAt: String?

    var userPhoto: UserPhoto {
        UserPhoto(
            id: id,
            placeID: placeId,
            placeName: placeName,
            status: status,
            isVerifiedCheckIn: isVerifiedCheckIn,
            showsAuthorName: showAuthorName,
            thumbnailURL: thumbnailUrl.flatMap(PlaceUserPhotoAPIResponse.allowedURL),
            imageURL: url.flatMap(PlaceUserPhotoAPIResponse.allowedURL),
            decisionReason: decisionReason.map(UserPhotoDecisionReason.init(code:)),
            createdAt: Self.date(createdAt) ?? .distantPast,
            decidedAt: decidedAt.flatMap(Self.date)
        )
    }

    private static func date(_ string: String) -> Date? {
        let withFraction = Date.ISO8601FormatStyle.iso8601.year().month().day().time(includingFractionalSeconds: true)
        if let date = try? Date(string, strategy: withFraction) {
            return date
        }
        return try? Date(string, strategy: .iso8601)
    }
}
