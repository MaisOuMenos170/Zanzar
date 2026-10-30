import Foundation

/// An entry of `images` in the place payloads: `{ url, credit: { author, license, sourceUrl } }`.
nonisolated struct PlaceImageAPIResponse: Decodable, Sendable {
    let url: String
    let credit: Credit?

    nonisolated struct Credit: Decodable, Sendable {
        let author: String
        let license: String
        let sourceUrl: String
    }

    /// `nil` unless the URL is `https`; a photo without a usable credit is still shown, just uncredited.
    var photo: PlacePhoto? {
        guard let url = Self.httpsURL(url) else { return nil }
        let credit = credit.flatMap { credit -> PhotoCredit? in
            guard let sourceURL = Self.httpsURL(credit.sourceUrl) else { return nil }
            return PhotoCredit(author: credit.author, license: credit.license, sourceURL: sourceURL)
        }
        return PlacePhoto(url: url, credit: credit)
    }

    /// The photos of a payload's `images` list, skipping malformed entries.
    static func photos(from images: [FailableDecodable<PlaceImageAPIResponse>]?) -> [PlacePhoto] {
        (images ?? []).compactMap { $0.value?.photo }
    }

    static func httpsURL(_ string: String) -> URL? {
        guard let url = URL(string: string), url.scheme?.lowercased() == "https" else { return nil }
        return url
    }
}
