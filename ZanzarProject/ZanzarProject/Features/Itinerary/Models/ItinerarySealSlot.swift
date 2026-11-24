import Foundation

struct ItinerarySealSlot: Identifiable, Hashable {
    let id: Int
    let category: ZanzarPlaceCategory
    let isEarned: Bool
}

extension ItineraryDetail {
    var requiredStops: Int {
        switch routeType {
        case .free: targetCount ?? placesCount
        case .fixed: places.isEmpty ? placesCount : places.count
        }
    }

    func sealCategory(forPlaceID placeID: String?, at index: Int) -> ZanzarPlaceCategory {
        if routeType == .free { return targetCategory ?? .unknown }
        if let placeID, let place = places.first(where: { $0.placeID == placeID }) { return place.category }
        return places.indices.contains(index) ? places[index].category : .unknown
    }

    func suggestedPlaces(from mapPlaces: [MapPlace], limit: Int = 2) -> [MapPlace] {
        let candidates: [MapPlace]
        switch routeType {
        case .fixed:
            let byID = Dictionary(mapPlaces.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
            candidates = places.map { place in
                byID[place.placeID] ?? MapPlace(
                    id: place.placeID,
                    name: place.name,
                    latitude: place.latitude,
                    longitude: place.longitude,
                    category: place.category,
                    distanceMeters: nil
                )
            }
        case .free:
            candidates = mapPlaces.filter { $0.category == targetCategory }
        }

        let notVisited = candidates.filter { $0.pinStyle != .checkedIn }
        return (notVisited.isEmpty ? candidates : notVisited)
            .sorted { ($0.distanceMeters ?? .infinity) < ($1.distanceMeters ?? .infinity) }
            .prefix(limit)
            .map { $0 }
    }
}

extension ItineraryDetailViewModel {
    var sealSlots: [ItinerarySealSlot] {
        guard let detail else { return [] }
        let required = detail.requiredStops
        var slots: [ItinerarySealSlot] = []
        if let activeItinerary, isCurrentItineraryActive {
            slots = activeItinerary.places.enumerated().map { index, slot in
                ItinerarySealSlot(
                    id: index,
                    category: detail.sealCategory(forPlaceID: slot.placeID, at: index),
                    isEarned: slot.isCompleted
                )
            }
        }
        let known = slots.count
        for index in known..<max(known, required) {
            let category = detail.sealCategory(forPlaceID: nil, at: index)
            slots.append(ItinerarySealSlot(id: index, category: category, isEarned: false))
        }
        return slots
    }

    var collectedCount: Int {
        sealSlots.filter(\.isEarned).count
    }
}

extension ItineraryDetail {
    var routeStops: [ItineraryDetailPlace] {
        routeType == .fixed ? places : []
    }
}

enum ItineraryRouteLink {
    static func url(for stops: [ItineraryDetailPlace]) -> URL? {
        guard !stops.isEmpty else { return nil }
        let destinations = stops
            .map { "\($0.latitude),\($0.longitude)" }
            .joined(separator: "+to:")
        var components = URLComponents(string: "https://maps.apple.com/")
        components?.queryItems = [
            URLQueryItem(name: "daddr", value: destinations),
            URLQueryItem(name: "dirflg", value: "w")
        ]
        return components?.url
    }
}
