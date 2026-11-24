import Foundation
import Observation

/// The user's suggested places with where each one stands.
@Observable
final class MySuggestionsViewModel {
    private(set) var suggestions: [MySuggestion] = []
    private(set) var isLoading = false
    private(set) var hasLoaded = false
    var errorMessage: String?

    private let service: PlaceSuggestionServicing

    init(service: PlaceSuggestionServicing = PlaceSuggestionService()) {
        self.service = service
    }

    func load() async {
        isLoading = true
        defer {
            isLoading = false
            hasLoaded = true
        }
        do {
            suggestions = try await service.fetchMine()
            errorMessage = nil
        } catch {
            guard !PlaceSuggestionErrorMapper.isCancellation(error) else { return }
            errorMessage = APIError.rateLimitedMessage(for: error)
                ?? L10n.string("placeSuggestion.mySuggestions.error.message")
        }
    }
}
