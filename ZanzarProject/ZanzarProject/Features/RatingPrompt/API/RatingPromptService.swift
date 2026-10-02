import Foundation

protocol RatingPromptServicing: Sendable {
    func hasRated(placeID: String) async throws -> Bool
    func submitRating(placeID: String, impressionTag: ImpressionTag) async throws
}

private struct RatingCreateRequest: Encodable, Sendable {
    let placeId: String
    let impressionTag: String
    let clientMutationId: String
}

private struct RatingResponse: Decodable, Sendable {
    let impressionTag: String
    let placeId: String
}

private struct UserRatingResponse: Decodable, Sendable {
    let impressionTag: String
}

final class RatingPromptService: RatingPromptServicing {
    private let client: NetworkClient

    init(client: NetworkClient = URLSessionNetworkClient.shared) {
        self.client = client
    }

    func hasRated(placeID: String) async throws -> Bool {
        do {
            let _: UserRatingResponse = try await client.get(
                path: "rating",
                queryItems: [URLQueryItem(name: "placeId", value: placeID)]
            )
            return true
        } catch APIError.httpStatus(404, _) {
            return false
        }
    }

    func submitRating(placeID: String, impressionTag: ImpressionTag) async throws {
        AppLog.ratingPrompt.info("Submitting rating placeId=\(placeID) tag=\(impressionTag.rawValue)...")
        do {
            let _: RatingResponse = try await client.send(
                path: "rating",
                method: .post,
                body: RatingCreateRequest(
                    placeId: placeID,
                    impressionTag: impressionTag.rawValue,
                    clientMutationId: UUID().uuidString
                )
            )
            AppLog.ratingPrompt.info("Submitted rating placeId=\(placeID) successfully")
        } catch APIError.httpStatus(409, let message) {
            AppLog.ratingPrompt.warning("Rating conflict (409) placeId=\(placeID)")
            throw APIError.httpStatus(409, message: message)
        } catch {
            AppLog.ratingPrompt.error("Failed to submit rating placeId=\(placeID)", error: error)
            throw error
        }
    }
}
