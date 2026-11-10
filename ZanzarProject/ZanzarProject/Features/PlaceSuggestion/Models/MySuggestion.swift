import Foundation

/// One of the user's suggestions and where it stands.
nonisolated struct MySuggestion: Identifiable, Hashable, Sendable {
    let id: String
    let status: PlaceSuggestionStatus
    /// Nil for suggestions typed by hand: nothing identified the place.
    let name: String?
    let address: String
    let note: String?
    let decisionReason: PlaceSuggestionDecisionReason?
    /// The place in the app, once approved (or the existing one when the suggestion was a duplicate).
    let placeID: String?
    let createdAt: Date
    let decidedAt: Date?

    /// What to call it on screen.
    var displayName: String {
        name ?? address
    }
}
