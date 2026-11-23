import Foundation
import Observation

/// The places the user bookmarked: the list, searching and filtering it, and taking a place off it.
@Observable
final class SavedPlacesViewModel {
    /// What happened when a place was taken off the list, for the toast that tells the user.
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
            // What is already on screen stays; only an empty screen needs the message.
            errorMessage = APIError.rateLimitedMessage(for: error) ?? L10n.string("savedPlaces.error.message")
        }
    }

    /// The places that match what is typed and the category chip. `category` says what each place is, when the app
    /// knows: the backend's list has no category, so a place the map has not loaded only shows under "Todos".
    func visiblePlaces(category: (SavedPlace) -> ZanzarPlaceCategory?) -> [SavedPlace] {
        places.filter { place in
            filter.includes(category(place))
                && (trimmedQuery.isEmpty || place.displayName.localizedStandardContains(trimmedQuery))
        }
    }

    /// Takes the place off the list at once and puts it back if the backend refuses.
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
