import Foundation

struct ProfileCheckIn: Identifiable, Hashable {
    let id: String
    let placeID: String
    let placeName: String?
    let date: Date
    let photoReference: String?
    let sealCategory: ZanzarPlaceCategory?
}

extension ProfileCheckIn {
    /// Minimal place used to open the detail screen, which loads the full place and the
    /// user's check-in state from the API. Coordinates and distance are unknown here.
    var mapPlace: MapPlace {
        MapPlace(
            id: placeID,
            name: placeName ?? "",
            latitude: 0,
            longitude: 0,
            category: sealCategory ?? .unknown,
            distanceMeters: nil,
            pinStyle: .checkedIn
        )
    }
}
