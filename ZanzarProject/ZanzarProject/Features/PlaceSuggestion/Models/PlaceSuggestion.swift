import Foundation

nonisolated struct PlaceSuggestion: Hashable, Sendable {
    let name: String
    let location: SuggestedLocation
    /// Optional: an empty note is left out of the request.
    let note: String

    /// The backend has no field for the name yet, so it travels in front of the address ("Jardim Botânico — Rua
    /// Engenheiro Ostoja Roguski, 350"), which is what the team reads when it reviews the suggestion.
    var addressText: String {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let address = location.address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return String(address.prefix(PlaceSuggestionLimits.addressMaxLength)) }

        let cutName = String(name.prefix(PlaceSuggestionLimits.nameMaxLength))
        guard !address.isEmpty else { return cutName }
        return String("\(cutName) — \(address)".prefix(PlaceSuggestionLimits.addressMaxLength))
    }
}

/// Mirrors the backend limits so the form can block a submit that would get a 400.
nonisolated enum PlaceSuggestionLimits {
    static let addressMaxLength = 300
    /// The name shares the backend's address field, so it has to leave room for the address.
    static let nameMaxLength = 100
    static let noteMaxLength = 1000
    static let queryMinLength = 2
    static let queryMaxLength = 120
}
