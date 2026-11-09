import Foundation

/// A photo of a place, served from a plain `https` URL: a curated one (with its licence credit)
/// or one a user sent (with its attribution).
nonisolated struct PlacePhoto: Hashable, Sendable {
    let url: URL
    let credit: PhotoCredit?
    let userAttribution: UserPhotoAttribution?

    init(url: URL, credit: PhotoCredit?, userAttribution: UserPhotoAttribution? = nil) {
        self.url = url
        self.credit = credit
        self.userAttribution = userAttribution
    }
}
