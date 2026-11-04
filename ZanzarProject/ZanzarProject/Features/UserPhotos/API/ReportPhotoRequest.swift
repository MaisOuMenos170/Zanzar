import Foundation

/// Body of `POST /places/{placeId}/photos/{photoId}/reports`.
nonisolated struct ReportPhotoRequest: Encodable, Sendable {
    let reason: String
    let note: String?
}
