import Foundation
import Observation

/// "Todos os lugares": the places around the user, nearest first, searchable by name and filterable by category.
@Observable
final class AllPlacesViewModel {
    var searchText = ""
    var filter = CategoryFilter.all

    var trimmedQuery: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// `places` filtered by category and by what is typed, the nearest first. A place whose distance is unknown
    /// goes last.
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
