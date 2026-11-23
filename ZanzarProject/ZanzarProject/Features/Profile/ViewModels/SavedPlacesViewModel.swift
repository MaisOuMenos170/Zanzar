import Foundation
import Observation

@Observable
final class SavedPlacesViewModel {
    enum RemoveOutcome: Equatable {
        case removed
        case failed(message: String)
    }

    private let service: SavedPlacesServicing
    private let userIDProvider: @Sendable () -> String?

    private(set) var places: [SavedPlace] = []
    private(set) var isLoading = false
    private(set) var hasLoaded = false
    private(set) var errorMessage: String?

    var searchText = ""
    var filter = CategoryFilter.all

    init(
        service: SavedPlacesServicing = SavedPlacesService(),
        userIDProvider: @escaping @Sendable () -> String? = { AuthTokenStore.shared.userID }
    ) {
        self.service = service
        self.userIDProvider = userIDProvider
    }

    var trimmedQuery: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func load() async {
        guard let userID = userIDProvider() else { return }
        isLoading = true
        defer {
            isLoading = false
            hasLoaded = true
        }
        do {
            places = try await service.fetchSavedPlaces(userID: userID)
            errorMessage = nil
        } catch is CancellationError {
            return
        } catch {
            errorMessage = APIError.rateLimitedMessage(for: error) ?? L10n.string("savedPlaces.error.message")
        }
    }

    func visiblePlaces(category: (SavedPlace) -> ZanzarPlaceCategory?) -> [SavedPlace] {
        places.filter { place in
            filter.includes(category(place))
                && (trimmedQuery.isEmpty || place.displayName.localizedStandardContains(trimmedQuery))
        }
    }

    @discardableResult
    func remove(_ place: SavedPlace) async -> RemoveOutcome? {
        guard let userID = userIDProvider(), let index = places.firstIndex(of: place) else { return nil }
        places.remove(at: index)
        do {
            try await service.remove(placeID: place.placeID, userID: userID)
            NotificationCenter.default.post(name: AppNotification.savedPlacesDidChange, object: nil)
            return .removed
        } catch is CancellationError {
            places.insert(place, at: min(index, places.count))
            return nil
        } catch {
            places.insert(place, at: min(index, places.count))
            return .failed(message: APIError.rateLimitedMessage(for: error)
                ?? L10n.string("placeDetail.saveButton.failedToast"))
        }
    }
}
