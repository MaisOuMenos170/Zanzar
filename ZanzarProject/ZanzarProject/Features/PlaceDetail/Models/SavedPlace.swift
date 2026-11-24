import Foundation

nonisolated struct SavedPlace: Identifiable, Hashable, Sendable {
    var id: String { placeID }

    let placeID: String
    let name: String?
    let imageURL: URL?
    let savedAt: Date

    var displayName: String {
        name ?? ""
    }

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
