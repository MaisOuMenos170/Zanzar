@testable import ZanzarProject

@MainActor
final class InMemoryPendingRatingStore: PendingRatingStoring {
    private(set) var stored: PendingRating?

    init(stored: PendingRating? = nil) {
        self.stored = stored
    }

    func load() -> PendingRating? { stored }
    func save(_ pendingRating: PendingRating) { stored = pendingRating }
    func clear() { stored = nil }
}
