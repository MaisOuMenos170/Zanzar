import Foundation

/// One seal of the ticket in the roteiro sheet: a place the roteiro asks the user to visit, earned or not yet.
struct ItinerarySealSlot: Identifiable, Hashable {
    let id: Int
    /// Which seal it is when earned. A free route asks for places of one category.
    let category: ZanzarPlaceCategory
    let isEarned: Bool
}

extension ItineraryDetail {
    /// How many places the roteiro asks the user to visit, which is how many seals its ticket has: the places of a
    /// fixed route, the number of places a free route asks for.
    var requiredStops: Int {
        switch routeType {
        case .free: targetCount ?? placesCount
        case .fixed: places.isEmpty ? placesCount : places.count
        }
    }

    /// The seal of the stop at `index`: the category of the roteiro for a free route, the category of that place
    /// for a fixed one.
    func sealCategory(forPlaceID placeID: String?, at index: Int) -> ZanzarPlaceCategory {
        if routeType == .free { return targetCategory ?? .unknown }
        if let placeID, let place = places.first(where: { $0.placeID == placeID }) { return place.category }
        return places.indices.contains(index) ? places[index].category : .unknown
    }

    /// The places to suggest under "Lugares próximos do roteiro": the ones the user has not visited yet, nearest
    /// first. A fixed route takes them from its own stops, a free one from the places of its category.
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
    /// The seals of the ticket: the progress of the roteiro the user follows, or empty seals when it is not theirs yet.
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
        // Whatever the roteiro asks for and the progress did not list yet is still a seal to earn.
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
    /// The stops "Ver rota" takes to Maps: only a fixed route knows them before the user checks in.
    var routeStops: [ItineraryDetailPlace] {
        routeType == .fixed ? places : []
    }
}

/// The link "Ver rota" opens: the stops of a roteiro in the user's maps app, on foot.
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
