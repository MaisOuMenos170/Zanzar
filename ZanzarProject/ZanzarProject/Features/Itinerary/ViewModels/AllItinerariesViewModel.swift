import Foundation
import Observation

@Observable
final class AllItinerariesViewModel {
    private let service: ItineraryServicing

    private(set) var itineraries: [Itinerary] = []
    private(set) var isLoading = false
    private(set) var hasLoaded = false
    private(set) var errorMessage: String?

    var searchText = ""
    var filter = ItineraryThemeFilter.all

    init(service: ItineraryServicing = ItineraryService()) {
        self.service = service
    }

    var trimmedQuery: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var visibleItineraries: [Itinerary] {
        itineraries.filter { itinerary in
            filter.includes(itinerary)
                && (trimmedQuery.isEmpty || itinerary.name.localizedStandardContains(trimmedQuery))
        }
    }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            itineraries = try await service.fetchItineraries()
            hasLoaded = true
        } catch is CancellationError {
            return
        } catch {
            guard itineraries.isEmpty else { return }
            errorMessage = APIError.rateLimitedMessage(for: error) ?? String(localized: "itinerary.errorState.message")
        }
    }
}
