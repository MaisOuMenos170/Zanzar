import Foundation

/// Body of `GET /user/{id}/photos`.
nonisolated struct UserPhotoListAPIResponse: Decodable, Sendable {
    let photos: [FailableDecodable<UserPhotoAPIResponse>]
}
