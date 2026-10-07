import Foundation

protocol ItineraryServicing: Sendable {
    func fetchItineraries() async throws -> [Itinerary]
    func fetchItineraryDetail(slug: String) async throws -> ItineraryDetail
    func activateItinerary(slug: String) async throws -> ActiveItinerary
    func abandonActiveItinerary() async throws
    func fetchActiveItinerary(userID: String) async throws -> ActiveItinerary?
}

struct ItineraryListItemAPIResponse: Decodable, Sendable {
    let slug: String
    let name: String
    let category: String
    let routeType: ItineraryRouteType
    let placesCount: Int
    let completedCount: Int
    let coverImageUrl: String?

    func makeItinerary() -> Itinerary {
        Itinerary(
            slug: slug,
            name: name,
            category: category,
            routeType: routeType,
            placesCount: placesCount,
            completedCount: completedCount,
            coverImageURL: coverImageUrl
        )
    }
}

struct ItineraryDetailAPIResponse: Decodable, Sendable {
    let slug: String
    let name: String
    let description: String
    let category: String
    let routeType: ItineraryRouteType
    let objectives: [String]
    let targetCategory: String?
    let targetCount: Int?
    let placesCount: Int
    let completedCount: Int
    let coverImageUrl: String?
    let places: [Place]

    struct Place: Decodable, Sendable {
        let placeId: String
        let name: String
        let location: Location

        struct Location: Decodable, Sendable {
            let lat: Double
            let lng: Double
        }
    }

    func makeItineraryDetail() -> ItineraryDetail {
        ItineraryDetail(
            slug: slug,
            name: name,
            description: description,
            category: category,
            routeType: routeType,
            objectives: objectives,
            targetCategory: targetCategory.flatMap { category in
                let parsed = ZanzarPlaceCategory(rawCategory: category)
                return parsed == .unknown ? nil : parsed
            },
            targetCount: targetCount,
            placesCount: placesCount,
            completedCount: completedCount,
            coverImageURL: coverImageUrl,
            places: places.map {
                ItineraryDetailPlace(
                    placeID: $0.placeId,
                    name: $0.name,
                    latitude: $0.location.lat,
                    longitude: $0.location.lng
                )
            }
        )
    }
}

struct ActiveItineraryAPIResponse: Decodable, Sendable {
    let itineraryTemplateId: String
    let slug: String
    let name: String
    let description: String
    let category: String
    let routeType: ItineraryRouteType
    let objectives: [String]
    let targetCategory: String?
    let targetCount: Int?
    let startedAt: String
    let places: [Place]

    struct Place: Decodable, Sendable {
        let placeId: String?
        let placeName: String?
        let isCompleted: Bool
        let datetime: String?
        let stamp: String?
    }

    func makeActiveItinerary() throws -> ActiveItinerary {
        ActiveItinerary(
            templateID: itineraryTemplateId,
            slug: slug,
            name: name,
            description: description,
            category: category,
            routeType: routeType,
            objectives: objectives,
            targetCategory: targetCategory.flatMap { category in
                let parsed = ZanzarPlaceCategory(rawCategory: category)
                return parsed == .unknown ? nil : parsed
            },
            targetCount: targetCount,
            startedAt: try Self.parseDate(startedAt),
            places: try places.enumerated().map { index, place in
                try ItinerarySlot(
                    id: place.placeId ?? "slot-\(index)",
                    placeID: place.placeId,
                    placeName: place.placeName,
                    isCompleted: place.isCompleted,
                    completedAt: place.datetime.flatMap { try? Self.parseDate($0) },
                    stampID: place.stamp
                )
            }
        )
    }

    private static func parseDate(_ value: String) throws -> Date {
        if let date = try? Date(value, strategy: Date.ISO8601FormatStyle(includingFractionalSeconds: true)) {
            return date
        }
        if let date = try? Date(value, strategy: Date.ISO8601FormatStyle()) {
            return date
        }
        throw APIError.decodingFailed
    }
}

final class ItineraryService: ItineraryServicing {
    private let client: NetworkClient

    init(client: NetworkClient = URLSessionNetworkClient.shared) {
        self.client = client
    }

    func fetchItineraries() async throws -> [Itinerary] {
        AppLog.itinerary.info("Fetching itinerary list")
        do {
            let response: [ItineraryListItemAPIResponse] = try await client.get(path: "itineraries")
            let itineraries = response.map { $0.makeItinerary() }
            AppLog.itinerary.info("Fetched itinerary list (count=\(itineraries.count))")
            return itineraries
        } catch {
            AppLog.itinerary.error("Itinerary list request failed", error: error)
            throw error
        }
    }

    func fetchItineraryDetail(slug: String) async throws -> ItineraryDetail {
        guard Self.isSafePathSegment(slug) else {
            AppLog.itinerary.error("Refusing to fetch detail for a malformed slug")
            throw APIError.invalidRequest
        }
        AppLog.itinerary.info("Fetching itinerary detail")
        do {
            let response: ItineraryDetailAPIResponse = try await client.get(path: "itineraries/\(slug)")
            let detail = response.makeItineraryDetail()
            AppLog.itinerary.info("Fetched itinerary detail (places=\(detail.places.count))")
            return detail
        } catch {
            AppLog.itinerary.error("Itinerary detail request failed", error: error)
            throw error
        }
    }

    func activateItinerary(slug: String) async throws -> ActiveItinerary {
        guard Self.isSafePathSegment(slug) else {
            AppLog.itinerary.error("Refusing to activate itinerary with a malformed slug")
            throw APIError.invalidRequest
        }
        AppLog.itinerary.info("Activating itinerary")
        do {
            let response: ActiveItineraryAPIResponse = try await client.send(
                path: "itineraries/\(slug)/activate",
                method: .post,
                body: EmptyJSONBody()
            )
            let active = try response.makeActiveItinerary()
            AppLog.itinerary.info("Activated itinerary (slots=\(active.places.count))")
            return active
        } catch {
            AppLog.itinerary.error("Activate itinerary request failed", error: error)
            throw error
        }
    }

    func abandonActiveItinerary() async throws {
        AppLog.itinerary.info("Abandoning active itinerary")
        do {
            try await client.sendWithoutResponse(path: "itineraries/active/abandon", method: .post)
            AppLog.itinerary.info("Abandoned active itinerary")
        } catch {
            AppLog.itinerary.error("Abandon itinerary request failed", error: error)
            throw error
        }
    }

    func fetchActiveItinerary(userID: String) async throws -> ActiveItinerary? {
        guard Self.isSafePathSegment(userID) else {
            AppLog.itinerary.error("Refusing to fetch active itinerary for a malformed user id")
            throw APIError.invalidRequest
        }
        AppLog.itinerary.info("Fetching active itinerary")
        do {
            let response: ActiveItineraryAPIResponse? = try await client.get(path: "user/\(userID)/itinerary")
            guard let response else {
                AppLog.itinerary.info("No active itinerary")
                return nil
            }
            let active = try response.makeActiveItinerary()
            AppLog.itinerary.info("Fetched active itinerary (slots=\(active.places.count))")
            return active
        } catch {
            AppLog.itinerary.error("Active itinerary request failed", error: error)
            throw error
        }
    }

    private static func isSafePathSegment(_ value: String) -> Bool {
        !value.isEmpty && value.allSatisfy { $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "-" || $0 == "_") }
    }
}

private struct EmptyJSONBody: Encodable {}
