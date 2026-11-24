import Foundation

/// What a shared map link or address says about a place. Any of it can be missing: a short link says nothing
/// until it is followed, and a plain address has no name.
nonisolated struct SharedPlaceHint: Equatable, Sendable {
    struct Coordinate: Hashable, Sendable {
        let latitude: Double
        let longitude: Double
    }

    var name: String?
    var address: String?
    var coordinate: Coordinate?

    init(name: String? = nil, address: String? = nil, coordinate: Coordinate? = nil) {
        self.name = name
        self.address = address
        self.coordinate = coordinate
    }

    var isEmpty: Bool { name == nil && address == nil && coordinate == nil }

    /// What to look the place up by: its name, else its address.
    var searchText: String? { name ?? address }
}
