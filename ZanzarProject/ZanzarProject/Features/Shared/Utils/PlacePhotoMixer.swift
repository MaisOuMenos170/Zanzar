import Foundation

/// The order of a place's photos: curated photos first, then photos sent by users, those sent with a check-in
/// before the others. The user's own photos under review go right after the curated ones so the author sees them.
/// At most `PlaceDetail.maximumPhotoCount` photos in all.
nonisolated enum PlacePhotoMixer {
    static func mix(curated: [PlacePhoto], user: [PlacePhoto], limit: Int) -> [PlacePhoto] {
        let ownUnderReview = user.filter { photo in
            guard let attribution = photo.userAttribution else { return false }
            return attribution.isOwn && attribution.status.isUnderReview
        }
        let approved = user.filter { $0.userAttribution?.status == .approved }
        let verified = approved.filter { $0.userAttribution?.isVerifiedCheckIn == true }
        let unverified = approved.filter { $0.userAttribution?.isVerifiedCheckIn != true }
        return Array((curated + ownUnderReview + verified + unverified).prefix(limit))
    }
}
