import Foundation

struct RatingSubmission: Sendable {
    let impressionTag: ImpressionTag
    let impressionCounts: [String: Int]?
}

protocol RatingPromptServicing: Sendable {
    func hasRated(placeID: String) async throws -> Bool
    func submitRating(placeID: String, impressionTag: ImpressionTag) async throws -> RatingSubmission
}

private struct RatingCreateRequest: Encodable, Sendable {
    let placeId: String
    let impressionTag: String
    let clientMutationId: String
}

private struct RatingResponse: Decodable, Sendable {
    let impressionTag: String
    let placeId: String
    let impressionCounts: [String: Int]?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        impressionTag = try container.decode(String.self, forKey: .impressionTag)
        placeId = try container.decode(String.self, forKey: .placeId)
        impressionCounts = try container.decodeIfPresent([String: Int].self, forKey: .impressionCounts)
    }

    private enum CodingKeys: String, CodingKey {
        case impressionTag
        case placeId
        case impressionCounts
    }
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
        AppLog.ratingPrompt.info("Checking existing rating placeId=\(placeID)...")
        do {
            let _: UserRatingResponse = try await client.get(
                path: "rating",
                queryItems: [URLQueryItem(name: "placeId", value: placeID)]
            )
            AppLog.ratingPrompt.info("Existing rating found placeId=\(placeID)")
            return true
        } catch APIError.httpStatus(404, _) {
            AppLog.ratingPrompt.info("No existing rating placeId=\(placeID)")
            return false
        } catch {
            AppLog.ratingPrompt.error("Failed to check existing rating placeId=\(placeID)", error: error)
            throw error
        }
    }

    func submitRating(placeID: String, impressionTag: ImpressionTag) async throws -> RatingSubmission {
        AppLog.ratingPrompt.info("Submitting rating placeId=\(placeID) tag=\(impressionTag.rawValue)...")
        do {
            let response: RatingResponse = try await client.send(
                path: "rating",
                method: .post,
                body: RatingCreateRequest(
                    placeId: placeID,
                    impressionTag: impressionTag.rawValue,
                    clientMutationId: UUID().uuidString
                )
            )
            if response.impressionCounts == nil {
                AppLog.ratingPrompt.warning(
                    "Rating response missing impressionCounts placeId=\(placeID); client will keep existing counts"
                )
            }
            AppLog.ratingPrompt.info("Submitted rating placeId=\(placeID) successfully")
            return RatingSubmission(
                impressionTag: ImpressionTag(rawValue: response.impressionTag) ?? impressionTag,
                impressionCounts: response.impressionCounts
            )
        } catch APIError.httpStatus(409, let message) {
            AppLog.ratingPrompt.warning("Rating conflict (409) placeId=\(placeID)")
            throw APIError.httpStatus(409, message: message)
        } catch {
            AppLog.ratingPrompt.error("Failed to submit rating placeId=\(placeID)", error: error)
            throw error
        }
    }
}
