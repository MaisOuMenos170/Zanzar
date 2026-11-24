import Foundation

/// Body of `POST /places/{placeId}/photos/{photoId}/reports`.
nonisolated struct AcceptedReportAPIResponse: Decodable, Sendable {
    let received: Bool
}
