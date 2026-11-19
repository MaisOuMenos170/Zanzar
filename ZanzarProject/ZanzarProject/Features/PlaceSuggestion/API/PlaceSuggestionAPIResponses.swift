import Foundation

/// A suggestion as `POST` and `GET /place-suggestions` return it.
nonisolated struct MySuggestionAPIResponse: Decodable, Sendable {
    let id: String
    let status: String
    let name: String?
    let address: String
    let note: String?
    let decisionReason: String?
    let placeId: String?
    let createdAt: String
    let decidedAt: String?

    private enum CodingKeys: String, CodingKey {
        case id = "_id"
        case status, name, address, note, decisionReason, placeId, createdAt, decidedAt
    }

    var mySuggestion: MySuggestion {
        MySuggestion(
            id: id,
            status: PlaceSuggestionStatus(code: status),
            name: name,
            address: address,
            note: note,
            decisionReason: decisionReason.map(PlaceSuggestionDecisionReason.init(code:)),
            placeID: placeId,
            createdAt: APIDate.parse(createdAt) ?? .distantPast,
            decidedAt: decidedAt.flatMap(APIDate.parse)
        )
    }
}
