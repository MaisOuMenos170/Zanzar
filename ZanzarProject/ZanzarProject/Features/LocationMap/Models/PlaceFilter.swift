import Foundation

/// What the discover filter keeps on the map and in the search results: places of the chosen types, and
/// optionally only the stops of the roteiro the user is following. An empty filter keeps everything.
nonisolated struct PlaceFilter: Equatable, Sendable {
    var categories: Set<ZanzarPlaceCategory> = []
    var onlyInItinerary = false

    var isActive: Bool {
        !categories.isEmpty || onlyInItinerary
    }

    /// How many choices are on, for the badge on the filter button.
    var activeCount: Int {
        categories.count + (onlyInItinerary ? 1 : 0)
    }

    func matches(_ place: MapPlace) -> Bool {
        if onlyInItinerary, !place.isInActiveItinerary { return false }
        return categories.isEmpty || categories.contains(place.category)
    }

    func apply(to places: [MapPlace]) -> [MapPlace] {
        isActive ? places.filter(matches) : places
    }

    mutating func toggle(_ category: ZanzarPlaceCategory) {
        if categories.contains(category) {
            categories.remove(category)
        } else {
            categories.insert(category)
        }
    }
}
