import Foundation

nonisolated struct PlaceSuggestion: Hashable, Sendable {
    let location: SuggestedLocation
    let note: String
}

/// Mirrors the backend limits so the form can block a submit that would get a 400.
nonisolated enum PlaceSuggestionLimits {
    static let addressMaxLength = 300
    static let noteMaxLength = 1000
}
