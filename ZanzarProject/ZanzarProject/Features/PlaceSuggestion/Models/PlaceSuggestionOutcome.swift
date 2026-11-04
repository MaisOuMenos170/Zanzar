import Foundation

nonisolated enum PlaceSuggestionOutcome: Hashable, Sendable {
    case success
    case failure(message: String)
}
