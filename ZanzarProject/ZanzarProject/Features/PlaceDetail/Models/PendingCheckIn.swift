import Foundation

/// A check-in the user made with no network, kept on the device until it can be sent. It carries everything the
/// request needs, including when the user really tapped and the id the backend uses to recognise a replay.
nonisolated struct PendingCheckIn: Codable, Equatable, Identifiable, Sendable {
    /// Also the `clientMutationId` of the request: sending it twice can never create two check-ins.
    let id: String
    let userID: String
    let placeID: String
    let placeName: String
    let latitude: Double
    let longitude: Double
    let accuracyMeters: Double?
    let checkedInAt: Date

    var coordinate: UserCoordinate {
        UserCoordinate(latitude: latitude, longitude: longitude, accuracyMeters: accuracyMeters)
    }
}
