import Foundation

nonisolated enum PlaceSuggestionOutcome: Hashable, Sendable {
    /// Sent and waiting for a person to look at it.
    case success
    /// Checked automatically and already in the app.
    case published(placeName: String)
    /// Checked automatically and not accepted.
    case refused(PlaceSuggestionDecisionReason)
    case failure(message: String)

    /// Whether the person gets good news (sent or published) rather than a refusal or a failure.
    var isGoodNews: Bool {
        switch self {
        case .success, .published: true
        case .refused, .failure: false
        }
    }
}
