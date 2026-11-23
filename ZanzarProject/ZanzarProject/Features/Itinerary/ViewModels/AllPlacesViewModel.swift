import Foundation
import Observation

@Observable
final class AllPlacesViewModel {
    var searchText = ""
    var filter = CategoryFilter.all

    var trimmedQuery: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func visiblePlaces(from places: [MapPlace]) -> [MapPlace] {
        places
            .filter { place in
                filter.includes(place.category)
                    && (trimmedQuery.isEmpty
                        || place.displayName.localizedStandardContains(trimmedQuery)
                        || place.name.localizedStandardContains(trimmedQuery))
            }
            .sorted { ($0.distanceMeters ?? .infinity) < ($1.distanceMeters ?? .infinity) }
    }
}
