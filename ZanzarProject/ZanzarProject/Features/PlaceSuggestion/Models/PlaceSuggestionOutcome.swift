import Foundation

nonisolated enum PlaceSuggestionOutcome: Hashable, Sendable {
    /// Sent and waiting for a person to look at it.
    case success
    /// Checked automatically and already in the app.
    case published(placeName: String)
    /// Checked automatically and not accepted.
    case refused(PlaceSuggestionDecisionReason)
    case failure(message: String)

    /// What the backend decided: the place is in the app, it was refused, or a person still has to look at it.
    init(_ suggestion: MySuggestion) {
        switch suggestion.status {
        case .approved:
            self = .published(placeName: suggestion.name ?? suggestion.displayName)
        case .rejected:
            self = .refused(suggestion.decisionReason ?? .other(""))
        case .pending, .needsReview:
            self = .success
        }
    }

    /// Whether the person gets good news (sent or published) rather than a refusal or a failure.
    var isGoodNews: Bool {
        switch self {
        case .success, .published: true
        case .refused, .failure: false
        }
    }

    /// The toast that tells the user how it went.
    @MainActor
    var toastMessage: String {
        switch self {
        case .success:
            L10n.string("placeSuggestion.toast.success")
        case .published(let placeName):
            L10n.string("placeSuggestion.toast.published", placeName)
        case .refused(let reason):
            L10n.string("placeSuggestion.toast.refused", L10n.string(reason.messageKey))
        case .failure(let message):
            message
        }
    }
}
