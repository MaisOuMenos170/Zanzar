import Foundation

struct ProfileCheckIn: Identifiable, Hashable {
    let id: String
    let placeName: String?
    let date: Date
    let photoReference: String?
    let sealCategory: ZanzarPlaceCategory?
}
