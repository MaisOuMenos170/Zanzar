import Foundation

nonisolated struct PlaceSuggestion: Hashable, Sendable {
    let name: String
    let location: SuggestedLocation
    /// Optional: an empty note is left out of the request.
    let note: String

    /// The address as the backend takes it, cut to its limit. The name travels in its own field; it only stands in
    /// for an address that is empty.
    var addressText: String {
        let address = location.address.trimmingCharacters(in: .whitespacesAndNewlines)
        let text = address.isEmpty ? trimmedName : address
        return String(text.prefix(PlaceSuggestionLimits.addressMaxLength))
    }

    /// `nil` for a suggestion without a name, so the request leaves the field out.
    var requestName: String? {
        trimmedName.isEmpty ? nil : String(trimmedName.prefix(PlaceSuggestionLimits.nameMaxLength))
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

/// Mirrors the backend limits so the form can block a submit that would get a 400.
nonisolated enum PlaceSuggestionLimits {
    static let addressMaxLength = 300
    static let nameMaxLength = 100
    static let noteMaxLength = 1000
    static let queryMinLength = 2
    static let queryMaxLength = 120
}
