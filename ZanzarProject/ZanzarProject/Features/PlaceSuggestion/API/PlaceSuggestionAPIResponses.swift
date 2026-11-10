import Foundation

/// One result of `GET /place-suggestions/search`. `category` is nil for kinds of place the app does not take.
nonisolated struct SuggestedPlaceAPIResponse: Decodable, Sendable {
    let osmType: String
    let osmId: Int
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
    let category: String?

    private static let knownTypes: Set<String> = ["node", "way", "relation"]

    /// Nil when the app could not suggest it anyway.
    var suggestedPlace: SuggestedPlace? {
        guard category != nil, Self.knownTypes.contains(osmType) else { return nil }
        return SuggestedPlace(
            osmType: osmType,
            osmID: osmId,
            name: name,
            address: address,
            latitude: latitude,
            longitude: longitude
        )
    }
}

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

nonisolated struct OSMPlaceSuggestionRequest: Encodable, Sendable {
    let osmType: String
    let osmId: Int
    let note: String?
}
