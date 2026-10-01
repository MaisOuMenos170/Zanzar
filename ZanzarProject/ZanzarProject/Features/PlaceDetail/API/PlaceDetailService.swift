import Foundation

protocol PlaceDetailServicing: Sendable {
    func fetchPlaceDetail(context: PlaceDetailLoadContext) async throws -> PlaceDetail
    func checkIn(placeID: String) async throws
    func submitReaction(placeID: String, impressionTag: String) async throws
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
    let placeId: String
    let datetime: String
    let clientMutationId: String
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

        async let hasCheckedIn = fetchHasCheckedIn(
            placeID: context.place.id,
            userID: context.userID
        )
        async let selectedReactionTag = fetchSelectedReactionTag(
            placeID: context.place.id,
            userID: context.userID
        )
        async let nearbyResponses = fetchNearbyPlaces(
            userCoordinate: context.userCoordinate,
            excludingPlaceID: context.place.id
        )

        return PlaceDetail.make(
            placeResponse: placeResponse,
            nearbyResponses: await nearbyResponses,
            mapPlace: context.place,
            hasCheckedIn: try await hasCheckedIn,
            selectedReactionTag: try await selectedReactionTag
        )
    }

    private func fetchNearbyPlaces(
        userCoordinate: UserCoordinate?,
        excludingPlaceID: String
    ) async -> [PlaceDetailAPIResponse] {
        guard let userCoordinate else { return [] }

        do {
            return try await client.get(
                path: "places",
                queryItems: [
                    URLQueryItem(name: "lat", value: String(userCoordinate.latitude)),
                    URLQueryItem(name: "lng", value: String(userCoordinate.longitude)),
                    URLQueryItem(name: "limit", value: "6"),
                    URLQueryItem(name: "excludePlaceId", value: excludingPlaceID),
                ]
            )
        } catch {
            return []
        }
    }

    func checkIn(placeID: String) async throws {
        let _: CheckInMessageResponse = try await client.send(
            path: "checkIn",
            method: .post,
            body: CheckInCreateRequest(
                placeId: placeID,
                datetime: Date().formatted(.iso8601),
                clientMutationId: UUID().uuidString
            )
        )
    }

    func submitReaction(placeID: String, impressionTag: String) async throws {
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
        guard userID != nil else { return false }

        do {
            let _: CheckInStatusResponse = try await client.get(
                path: "checkIn",
                queryItems: [URLQueryItem(name: "placeId", value: placeID)]
            )
            return true
        } catch APIError.httpStatus(404, _) {
            return false
        } catch APIError.httpStatus(401, _), APIError.httpStatus(403, _) {
            return false
        }
    }

    private func fetchSelectedReactionTag(placeID: String, userID: String?) async throws -> String? {
        guard userID != nil else { return nil }

        do {
            let response: UserRatingResponse = try await client.get(
                path: "rating",
                queryItems: [URLQueryItem(name: "placeId", value: placeID)]
            )
            return response.impressionTag
        } catch APIError.httpStatus(404, _) {
            return nil
        } catch APIError.httpStatus(401, _), APIError.httpStatus(403, _) {
            return nil
        }
    }
}

private struct CheckInMessageResponse: Decodable, Sendable {
    let message: String
}
