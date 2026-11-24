import Foundation

/// Where a suggested place stands. `approved` means the place is already in the app.
nonisolated enum PlaceSuggestionStatus: String, Sendable, Hashable {
    case pending
    case needsReview = "needs_review"
    case approved
    case rejected

    /// Still waiting for the automatic or the human review.
    var isUnderReview: Bool {
        self == .pending || self == .needsReview
    }

    /// An unknown status from a newer backend is shown as "in review" instead of failing the whole list.
    init(code: String) {
        self = Self(rawValue: code) ?? .needsReview
    }
}
