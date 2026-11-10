import Foundation
import Observation

/// When the app opens, tells the user about suggestions whose review finished since they last looked.
@Observable
final class SuggestionStatusNoticeViewModel {
    private let service: PlaceSuggestionServicing
    private let store: PlaceSuggestionStatusStoring
    private let now: () -> Date

    /// A decision this soon after the suggestion was sent came from the automatic check, in the same request.
    static let instantDecisionWindow: TimeInterval = 30

    init(
        service: PlaceSuggestionServicing = PlaceSuggestionService(),
        store: PlaceSuggestionStatusStoring = UserDefaultsPlaceSuggestionStatusStore(),
        now: @escaping () -> Date = { Date() }
    ) {
        self.service = service
        self.store = store
        self.now = now
    }

    /// The message to show, or `nil` when nothing changed. The first run only records what is there.
    func checkForChanges() async -> String? {
        guard let suggestions = try? await service.fetchMine() else { return nil }
        let previous = store.lastSeenStatuses()
        let lastCheck = store.lastCheckedAt()
        let current = Dictionary(uniqueKeysWithValues: suggestions.map { ($0.id, $0.status.rawValue) })
        store.save(current, checkedAt: now())
        guard let lastCheck else { return nil }

        let changed = suggestions.filter { suggestion in
            guard !suggestion.status.isUnderReview else { return false }
            if let before = previous[suggestion.id] {
                return before != suggestion.status.rawValue
            }
            // Not seen before: sent and decided since the last look. A decision made while the request was still
            // being answered was already told on the sheet, so only slower (human) decisions count.
            guard let decidedAt = suggestion.decidedAt, decidedAt > lastCheck else { return false }
            return decidedAt.timeIntervalSince(suggestion.createdAt) > Self.instantDecisionWindow
        }
        let added = changed.filter { $0.status == .approved }.count
        let refused = changed.count - added
        switch (added, refused) {
        case (0, 0): return nil
        case (_, 0): return L10n.string("placeSuggestion.notice.added", added)
        case (0, _): return L10n.string("placeSuggestion.notice.notApproved", refused)
        default: return L10n.string("placeSuggestion.notice.mixed", added, refused)
        }
    }
}
