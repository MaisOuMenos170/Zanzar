import Foundation

struct ProfileCheckIn: Identifiable, Hashable {
    let id: UUID
    let placeName: String
    let date: Date
    let impressionImageName: String
    let reactionImageName: String?
}
