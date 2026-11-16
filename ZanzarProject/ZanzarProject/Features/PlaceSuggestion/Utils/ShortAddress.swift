import Foundation

/// A full address as the geocoder writes it ("Rua XV de Novembro, 1234, Centro, Curitiba - PR, 80020-310, Brasil")
/// without its postal code ("Rua XV de Novembro, 1234, Centro, Curitiba - PR, Brasil"). An address that has no
/// postal code is returned as it is.
nonisolated enum ShortAddress {
    static func format(_ address: String) -> String {
        let parts = address
            .split(separator: ",", omittingEmptySubsequences: true)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        // A single piece is something the user typed (or a plain name): nothing to cut.
        guard parts.count > 1 else { return address.trimmingCharacters(in: .whitespacesAndNewlines) }

        let kept = parts.filter { !isPostalCode($0) }
        return kept.isEmpty ? address : kept.joined(separator: ", ")
    }

    /// A Brazilian postal code: "80020-310" or "80020310".
    private static func isPostalCode(_ part: String) -> Bool {
        part.wholeMatch(of: /\d{5}-?\d{3}/) != nil
    }
}
