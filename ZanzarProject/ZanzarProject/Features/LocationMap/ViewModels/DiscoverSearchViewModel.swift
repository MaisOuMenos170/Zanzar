import Foundation
import Observation

/// The search bar of the discover screen: looks places up on the backend as the user types and keeps the
/// filter chosen next to it. Results come back nearest first and are shown in that order.
@Observable
final class DiscoverSearchViewModel {
    enum Phase: Equatable {
        /// Nothing typed yet (or fewer characters than the backend accepts).
        case idle
        case searching
        case results
        case failed
    }

    /// The backend refuses shorter texts.
    static let minimumQueryLength = 2

    private let service: PlaceSearchServicing
    private let coordinateProvider: () -> UserCoordinate?
    private let debounce: Duration
    private var searchTask: Task<Void, Never>?

    var query = "" {
        didSet {
            guard query != oldValue else { return }
            scheduleSearch(afterDebounce: true)
        }
    }

    var filter = PlaceFilter() {
        didSet {
            guard filter != oldValue else { return }
            scheduleSearch(afterDebounce: false)
        }
    }

    private(set) var results: [MapPlace] = []
    private(set) var phase: Phase = .idle

    init(
        service: PlaceSearchServicing = PlaceSearchService(),
        coordinateProvider: @escaping () -> UserCoordinate?,
        debounce: Duration = .milliseconds(300)
    ) {
        self.service = service
        self.coordinateProvider = coordinateProvider
        self.debounce = debounce
    }

    var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var canSearch: Bool {
        trimmedQuery.count >= Self.minimumQueryLength
    }

    /// The panel of results is shown while there is something to say about the text typed.
    var showsResultsPanel: Bool {
        canSearch
    }

    /// Clears the text and the results, e.g. after the user opened one of them.
    func reset() {
        searchTask?.cancel()
        searchTask = nil
        query = ""
        results = []
        phase = .idle
    }

    /// Searches right away, skipping the pause for typing (the keyboard's search key).
    func submit() {
        scheduleSearch(afterDebounce: false)
    }

    /// Runs the search that is pending, for callers that need to wait for it (tests, previews).
    func waitForSearch() async {
        await searchTask?.value
    }

    private func scheduleSearch(afterDebounce: Bool) {
        searchTask?.cancel()
        searchTask = nil

        guard canSearch else {
            results = []
            phase = .idle
            return
        }

        phase = .searching
        let text = trimmedQuery
        let currentFilter = filter
        let pause = afterDebounce ? debounce : .zero
        searchTask = Task { [weak self] in
            if pause > .zero {
                try? await Task.sleep(for: pause)
            }
            guard !Task.isCancelled else { return }
            await self?.search(text: text, filter: currentFilter)
        }
    }

    private func search(text: String, filter: PlaceFilter) async {
        guard let coordinate = coordinateProvider() else {
            // Without a position the backend cannot rank by distance.
            results = []
            phase = .failed
            return
        }
        do {
            let found = try await service.searchPlaces(query: text, near: coordinate, categories: filter.categories)
            guard !Task.isCancelled else { return }
            // The backend does not know which places belong to the user's roteiro.
            results = filter.onlyInItinerary ? found.filter(filter.matches) : found
            phase = .results
        } catch {
            guard !Task.isCancelled, !Self.isCancellation(error) else { return }
            results = []
            phase = .failed
        }
    }

    private static func isCancellation(_ error: Error) -> Bool {
        if error is CancellationError { return true }
        if (error as? URLError)?.code == .cancelled { return true }
        let nsError = error as NSError
        return nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled
    }
}
