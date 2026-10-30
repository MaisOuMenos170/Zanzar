import Foundation

/// A photo of a place, served from a plain `https` URL.
nonisolated struct PlacePhoto: Hashable, Sendable {
    let url: URL
    let credit: PhotoCredit?
}
