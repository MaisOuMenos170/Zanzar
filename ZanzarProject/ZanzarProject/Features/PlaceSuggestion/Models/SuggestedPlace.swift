import Foundation

/// A place Apple Maps found for what the user typed. Either piece of text can be missing: an address with no
/// name attached (a street number, a neighborhood) or a named place Apple has no address for. The form asks
/// the user for whichever one is missing. The position is always known.
nonisolated struct SuggestedPlace: Identifiable, Hashable, Sendable {
    let name: String?
    let address: String?
    let latitude: Double
    let longitude: Double

    var id: String { "\(latitude),\(longitude)|\(name ?? "")|\(address ?? "")" }

    var hasName: Bool { name != nil }
    var hasAddress: Bool { address != nil }

    /// What the result list shows in bold: the name, or the address when there is no name.
    var title: String { name ?? address ?? "" }

    /// The text that stands for the place in the search field once it is chosen: its name and its address, or
    /// whichever of the two it has.
    var searchFieldText: String {
        let shortAddress = address.map(ShortAddress.format)
        return [name, shortAddress].compactMap(\.self).joined(separator: ", ")
    }
}
