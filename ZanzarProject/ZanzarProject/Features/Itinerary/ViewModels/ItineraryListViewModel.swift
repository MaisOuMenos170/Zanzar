import Foundation
import Observation

@Observable
final class ItineraryListViewModel {
    private let itineraryService: ItineraryServicing
    private let locationService: LocationMapServicing
    private let userIDProvider: @Sendable () -> String?
    private var loadGeneration = 0

    var itineraries: [Itinerary] = []
    var nearbyPlaces: [PlaceDetailNearbyPlace] = []
    var activeItinerary: ActiveItinerary?
    var isLoading = false
    var errorMessage: String?
    var actionErrorMessage: String?

    var showsActionError: Bool {
        get { actionErrorMessage != nil }
        set { if !newValue { actionErrorMessage = nil } }
    }

    init(
        itineraryService: ItineraryServicing = ItineraryService(),
        locationService: LocationMapServicing = LocationMapService(),
        userIDProvider: @escaping @Sendable () -> String? = { AuthTokenStore.shared.getToken().flatMap(JWTDecoder.userID(from:)) }
    ) {
        self.itineraryService = itineraryService
        self.locationService = locationService
        self.userIDProvider = userIDProvider
    }

    func load() async {
        loadGeneration += 1
        let generation = loadGeneration

        isLoading = true
        errorMessage = nil
        defer {
            if generation == loadGeneration {
                isLoading = false
            }
        }

        async let itinerariesTask = itineraryService.fetchItineraries()
        async let activeTask = fetchActiveItineraryIfAuthenticated()
        async let nearbyTask = fetchNearbyPlaces()

        do {
            let loadedItineraries = try await itinerariesTask
            guard generation == loadGeneration else { return }
            itineraries = loadedItineraries
        } catch is CancellationError {
            return
        } catch {
            guard generation == loadGeneration, itineraries.isEmpty else { return }
            errorMessage = String(localized: "itinerary.errorState.message")
            return
        }

        do {
            let loadedActive = try await activeTask
            guard generation == loadGeneration else { return }
            activeItinerary = loadedActive
        } catch is CancellationError {
            return
        } catch {
            AppLog.itinerary.warning("Failed to fetch active itinerary")
        }

        let loadedNearby = await nearbyTask
        guard generation == loadGeneration else { return }
        nearbyPlaces = loadedNearby
    }

    func refreshActiveItinerary() async {
        do {
            activeItinerary = try await fetchActiveItineraryIfAuthenticated()
        } catch is CancellationError {
            return
        } catch {
            AppLog.itinerary.warning("Failed to refresh active itinerary")
        }
    }

    func abandonActiveItinerary() async {
        actionErrorMessage = nil
        do {
            try await itineraryService.abandonActiveItinerary()
            activeItinerary = nil
            NotificationCenter.default.post(name: AppNotification.activeItineraryDidChange, object: nil)
        } catch is CancellationError {
            return
        } catch {
            AppLog.itinerary.error("Failed to abandon active itinerary", error: error)
            actionErrorMessage = String(localized: "itinerary.detail.actionError.generic")
        }
    }

    private func fetchActiveItineraryIfAuthenticated() async throws -> ActiveItinerary? {
        guard let userID = userIDProvider() else { return nil }
        return try await itineraryService.fetchActiveItinerary(userID: userID)
    }

    private func fetchNearbyPlaces() async -> [PlaceDetailNearbyPlace] {
        do {
            let coordinate = try await locationService.currentUserLocation()
            let places = try await locationService.fetchNearbyPlaces(from: coordinate)
            return places.map(PlaceDetailNearbyPlace.init(mapPlace:))
        } catch is CancellationError {
            return []
        } catch {
            AppLog.itinerary.warning("Nearby places unavailable on check-in tab")
            return []
        }
    }
}
