import Foundation

/// Body of `GET /places/{placeId}/photos`.
nonisolated struct PlaceUserPhotoListAPIResponse: Decodable, Sendable {
    let photos: [FailableDecodable<PlaceUserPhotoAPIResponse>]

    var placePhotos: [PlacePhoto] {
        photos.compactMap { $0.value?.photo }
    }
}
