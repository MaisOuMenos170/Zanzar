import Foundation

protocol PlaceDetailServicing: Sendable {
    func fetchPlaceDetail(context: PlaceDetailLoadContext) async throws -> PlaceDetail
    func checkIn(placeID: String, userID: String) async throws
    func submitReaction(placeID: String, userID: String, impressionTag: String) async throws
}

struct PlaceDetailAPIResponse: Decodable, Sendable {
    let placeId: String
    let name: String
    let formattedAddress: String?
    let geometry: Geometry
    let editorialSummary: EditorialSummary?
    let openingHours: OpeningHours?
    let photos: [Photo]
    let zanzar: Zanzar
    let distanceMeters: Double?

    enum CodingKeys: String, CodingKey {
        case placeId = "place_id"
        case name
        case formattedAddress = "formatted_address"
        case geometry
        case editorialSummary = "editorial_summary"
        case openingHours = "opening_hours"
        case photos
        case zanzar
        case distanceMeters
    }

    struct Geometry: Decodable, Sendable {
        let location: Location
    }

    struct Location: Decodable, Sendable {
        let lat: Double
        let lng: Double
    }

    struct EditorialSummary: Decodable, Sendable {
        let overview: String
    }

    struct OpeningHours: Decodable, Sendable {
        let openNow: Bool?

        enum CodingKeys: String, CodingKey {
            case openNow = "open_now"
        }
    }

    struct Photo: Decodable, Sendable {
        let photoReference: String
        let height: Int
        let width: Int

        enum CodingKeys: String, CodingKey {
            case photoReference = "photo_reference"
            case height
            case width
        }
    }

    struct Zanzar: Decodable, Sendable {
        let category: String
        let tags: [String]
        let checkInCount: Int
        let impressionCounts: [String: Int]

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            category = try container.decode(String.self, forKey: .category)
            tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
            checkInCount = try container.decodeIfPresent(Int.self, forKey: .checkInCount) ?? 0
            impressionCounts = try container.decodeIfPresent([String: Int].self, forKey: .impressionCounts) ?? [:]
        }

        private enum CodingKeys: String, CodingKey {
            case category
            case tags
            case checkInCount
            case impressionCounts
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        placeId = try container.decode(String.self, forKey: .placeId)
        name = try container.decode(String.self, forKey: .name)
        formattedAddress = try container.decodeIfPresent(String.self, forKey: .formattedAddress)
        geometry = try container.decode(Geometry.self, forKey: .geometry)
        editorialSummary = try container.decodeIfPresent(EditorialSummary.self, forKey: .editorialSummary)
        openingHours = try container.decodeIfPresent(OpeningHours.self, forKey: .openingHours)
        photos = try container.decodeIfPresent([Photo].self, forKey: .photos) ?? []
        zanzar = try container.decode(Zanzar.self, forKey: .zanzar)
        distanceMeters = try container.decodeIfPresent(Double.self, forKey: .distanceMeters)
    }
}

private struct CheckInCreateRequest: Encodable, Sendable {
    let userId: String
    let placeId: String
}

private struct CheckInStatusResponse: Decodable, Sendable {
    let placeId: String
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

final class PlaceDetailService: PlaceDetailServicing {
    private let client: NetworkClient

    init(client: NetworkClient = URLSessionNetworkClient.shared) {
        self.client = client
    }

    func fetchPlaceDetail(context: PlaceDetailLoadContext) async throws -> PlaceDetail {
        let placeResponse: PlaceDetailAPIResponse = try await client.get(
            path: "places/\(context.place.id)"
        )

        let nearbyResponses: [PlaceDetailAPIResponse] = try await client.get(
            path: "places",
            queryItems: [
                URLQueryItem(name: "lat", value: String(placeResponse.geometry.location.lat)),
                URLQueryItem(name: "lng", value: String(placeResponse.geometry.location.lng)),
                URLQueryItem(name: "limit", value: "8"),
            ]
        )

        let hasCheckedIn = try await fetchHasCheckedIn(
            placeID: context.place.id,
            userID: context.userID
        )
        let selectedReactionTag = try await fetchSelectedReactionTag(
            placeID: context.place.id,
            userID: context.userID
        )

        return PlaceDetail.make(
            placeResponse: placeResponse,
            nearbyResponses: nearbyResponses,
            mapPlace: context.place,
            hasCheckedIn: hasCheckedIn,
            selectedReactionTag: selectedReactionTag
        )
    }

    func checkIn(placeID: String, userID: String) async throws {
        let _: CheckInMessageResponse = try await client.send(
            path: "checkIn",
            method: .post,
            body: CheckInCreateRequest(userId: userID, placeId: placeID)
        )
    }

    func submitReaction(placeID: String, userID: String, impressionTag: String) async throws {
        let _: RatingResponse = try await client.send(
            path: "rating",
            method: .post,
            body: RatingCreateRequest(
                placeId: placeID,
                impressionTag: impressionTag,
                clientMutationId: UUID().uuidString
            )
        )
    }

    private func fetchHasCheckedIn(placeID: String, userID: String?) async throws -> Bool {
        guard let userID else { return false }

        do {
            let _: CheckInStatusResponse = try await client.get(
                path: "checkIn",
                queryItems: [
                    URLQueryItem(name: "placeId", value: placeID),
                    URLQueryItem(name: "userId", value: userID),
                ]
            )
            return true
        } catch APIError.httpStatus(404, _) {
            return false
        }
    }

    private func fetchSelectedReactionTag(placeID: String, userID: String?) async throws -> String? {
        guard let userID else { return nil }

        do {
            let response: UserRatingResponse = try await client.get(
                path: "rating",
                queryItems: [URLQueryItem(name: "placeId", value: placeID)]
            )
            return response.impressionTag
        } catch APIError.httpStatus(404, _) {
            return nil
        }
    }
}

private struct CheckInMessageResponse: Decodable, Sendable {
    let message: String
}
