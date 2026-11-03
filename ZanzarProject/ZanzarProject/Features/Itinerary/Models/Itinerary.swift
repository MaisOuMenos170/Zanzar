import Foundation

enum ItineraryRouteType: String, Codable, Sendable, Hashable {
    case fixed
    case free
}

struct Itinerary: Identifiable, Hashable, Sendable {
    var id: String { slug }

    let slug: String
    let name: String
    let category: String
    let routeType: ItineraryRouteType
    let placesCount: Int
    let completedCount: Int
    let coverImageURL: String?
}

struct ItineraryDetailPlace: Hashable, Sendable, Identifiable {
    var id: String { placeID }

    let placeID: String
    let name: String
    let latitude: Double
    let longitude: Double
    let category: ZanzarPlaceCategory

    init(
        placeID: String,
        name: String,
        latitude: Double,
        longitude: Double,
        category: ZanzarPlaceCategory = .unknown
    ) {
        self.placeID = placeID
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.category = category
    }
}

struct ItineraryDetail: Hashable, Sendable {
    let slug: String
    let name: String
    let description: String
    let category: String
    let routeType: ItineraryRouteType
    let objectives: [String]
    let targetCategory: ZanzarPlaceCategory?
    let targetCount: Int?
    let placesCount: Int
    let completedCount: Int
    let coverImageURL: String?
    let places: [ItineraryDetailPlace]
}

struct ItinerarySlot: Hashable, Sendable, Identifiable {
    let id: String
    let placeID: String?
    let placeName: String?
    let isCompleted: Bool
    let completedAt: Date?
    let stampID: String?
}

struct ActiveItinerary: Hashable, Sendable {
    let templateID: String
    let slug: String
    let name: String
    let description: String
    let category: String
    let routeType: ItineraryRouteType
    let objectives: [String]
    let targetCategory: ZanzarPlaceCategory?
    let targetCount: Int?
    let startedAt: Date
    let places: [ItinerarySlot]
}

extension ActiveItinerary {
    /// Cards for the places of this itinerary, in route order, built from the places the map already loaded.
    /// Slots without a place yet (free routes) and places the map does not know are left out.
    func placeCards(from mapPlaces: [MapPlace]) -> [PlaceDetailNearbyPlace] {
        let mapPlacesByID = Dictionary(mapPlaces.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        return places.compactMap { slot in
            slot.placeID
                .flatMap { mapPlacesByID[$0] }
                .map(PlaceDetailNearbyPlace.init(mapPlace:))
        }
    }
}
