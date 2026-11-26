import Foundation
import Observation

@Observable
final class AllPlacesViewModel {
    var searchText = ""
    var filter = CategoryFilter.all
    /// Why the places could not be loaded, for as long as that is true. An empty list and a list that failed to
    /// load are not the same thing.
    private(set) var loadErrorMessage: String?

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

    /// Loads the shared places. `force` goes to the server even when they are fresh (pull to refresh, retry).
    func load(using store: NearbyPlacesStore, force: Bool = false) async {
        do {
            if force {
                try await store.refresh()
            } else {
                try await store.refreshIfNeeded()
            }
            loadErrorMessage = nil
        } catch is CancellationError {
            return
        } catch let error as URLError where error.code == .cancelled {
            return
        } catch let error as LocationMapError {
            loadErrorMessage = error.errorDescription ?? L10n.string("locationMap.placesLoadError")
        } catch {
            loadErrorMessage = APIError.rateLimitedMessage(for: error) ?? L10n.string("locationMap.placesLoadError")
        }
    }
}
