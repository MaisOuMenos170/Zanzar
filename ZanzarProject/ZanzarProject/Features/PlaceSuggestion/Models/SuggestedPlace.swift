import Foundation

/// A place found on OpenStreetMap that the user can suggest. Only its OpenStreetMap id is sent back:
/// the backend looks the place up again and never trusts the name or position from the app.
nonisolated struct SuggestedPlace: Identifiable, Hashable, Sendable {
    let osmType: String
    let osmID: Int
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double

    var id: String { "\(osmType)/\(osmID)" }
}
