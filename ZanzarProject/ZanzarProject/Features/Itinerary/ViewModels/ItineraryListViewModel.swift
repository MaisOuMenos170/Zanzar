import Foundation
import Observation

@Observable
final class ItineraryListViewModel {
    private let itineraryService: ItineraryServicing
    private let userIDProvider: @Sendable () -> String?
    private let now: () -> Date
    private var loadGeneration = 0
    private var lastLoadedAt: Date?

    var itineraries: [Itinerary] = []
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
        userIDProvider: @escaping @Sendable () -> String? = { AuthTokenStore.shared.userID },
        now: @escaping () -> Date = { Date() }
    ) {
        self.itineraryService = itineraryService
        self.userIDProvider = userIDProvider
        self.now = now
    }

    /// Re-entering the tab within `DataFreshness.screenMaxAge` keeps what is shown (the active itinerary is
    /// kept current by `refreshActiveItinerary`); pull-to-refresh and retry pass `force`.
    func load(force: Bool = false) async {
        if !force, !itineraries.isEmpty, let lastLoadedAt,
           now().timeIntervalSince(lastLoadedAt) < DataFreshness.screenMaxAge / .seconds(1) {
            return
        }

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

        do {
            let loadedItineraries = try await itinerariesTask
            guard generation == loadGeneration else { return }
            itineraries = loadedItineraries
        } catch is CancellationError {
            return
        } catch {
            guard generation == loadGeneration, itineraries.isEmpty else { return }
            errorMessage = APIError.rateLimitedMessage(for: error) ?? String(localized: "itinerary.errorState.message")
            return
        }

        do {
            let loadedActive = try await activeTask
            guard generation == loadGeneration else { return }
            activeItinerary = loadedActive
            lastLoadedAt = now()
        } catch is CancellationError {
            return
        } catch {
            AppLog.itinerary.warning("Failed to fetch active itinerary")
        }
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
            actionErrorMessage = APIError.rateLimitedMessage(for: error)
                ?? String(localized: "itinerary.detail.actionError.generic")
        }
    }

    private func fetchActiveItineraryIfAuthenticated() async throws -> ActiveItinerary? {
        guard let userID = userIDProvider() else { return nil }
        return try await itineraryService.fetchActiveItinerary(userID: userID)
    }
}
