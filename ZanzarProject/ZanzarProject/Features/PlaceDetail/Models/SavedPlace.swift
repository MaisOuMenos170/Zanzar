import Foundation

/// A place the user bookmarked, as the "Lugares salvos" list shows it.
nonisolated struct SavedPlace: Identifiable, Hashable, Sendable {
    var id: String { placeID }

    let placeID: String
    /// `nil` when the backend no longer has the place's name.
    let name: String?
    let imageURL: URL?
    let savedAt: Date

    var displayName: String {
        name ?? ""
    }

    /// Minimal place used to open the detail screen, which loads the full place from the API. Coordinates and
    /// distance are unknown here.
    func mapPlace(category: ZanzarPlaceCategory?) -> MapPlace {
        MapPlace(
            id: placeID,
            name: displayName,
            latitude: 0,
            longitude: 0,
            category: category ?? .unknown,
            distanceMeters: nil
        )
    }
}
