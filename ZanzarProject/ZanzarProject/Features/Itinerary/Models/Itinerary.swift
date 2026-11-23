import Foundation

enum ItineraryRouteType: String, Codable, Sendable, Hashable {
    case fixed
    case free
}

/// What a roteiro is about, as the backend tags it (`itinerary-themes.ts`). They are the filter chips of the
/// "Todos os roteiros" list, and are not place categories: `food` groups restaurants, bars and cafés.
enum ItineraryTheme: String, CaseIterable, Sendable, Hashable {
    case parks
    case center
    case food
    case museums
    case walking
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
    /// Empty for a roteiro the backend has not tagged yet; it then only shows under "Todos".
    var themes: [ItineraryTheme] = []
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
    /// Avatars of the last people who finished it, most recent first (up to 5). They have no id or name.
    var recentCompleters: [Avatar] = []
}

extension ItineraryDetail {
    /// Cards for the places of this itinerary. A place the map already loaded brings its photo, check-ins and
    /// reactions; one it does not know is still shown, from what the itinerary itself says about it.
    func placeCards(from mapPlaces: [MapPlace]) -> [PlaceDetailNearbyPlace] {
        let mapPlacesByID = Dictionary(mapPlaces.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        return places.map { place in
            PlaceDetailNearbyPlace(
                mapPlace: mapPlacesByID[place.placeID] ?? MapPlace(
                    id: place.placeID,
                    name: place.name,
                    latitude: place.latitude,
                    longitude: place.longitude,
                    category: place.category,
                    distanceMeters: nil
                )
            )
        }
    }
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

extension ActiveItinerary {
    /// Tells one run of a roteiro from the next, so abandoning and starting it again alerts its stops again.
    var runID: String {
        "\(templateID)@\(Int(startedAt.timeIntervalSince1970))"
    }

    /// The stop the user should go to next: the first slot that has a place and is not completed yet.
    /// Free routes have no place per slot until the user checks in, so they have none.
    var nextPendingPlaceID: String? {
        places.first { $0.placeID != nil && !$0.isCompleted }?.placeID
    }
}
