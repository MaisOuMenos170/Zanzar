import Foundation
import Observation

/// Carries "the user tapped the alert for this place" from the notification system to the screen that shows places.
///
/// A tap can start the app, before any screen exists, so it waits here until the main screen picks it up. A tap that
/// nobody picks up soon is dropped: it must not open a place minutes later, after the user signed in.
@Observable
final class ProximityAlertRouter {
    static let shared = ProximityAlertRouter()

    /// How long a tap stays valid while waiting for the main screen.
    static let tapLifetime: TimeInterval = 120

    private(set) var pendingPlaceID: String?
    private var tappedAt: Date?

    func open(placeID: String, now: Date = Date()) {
        pendingPlaceID = placeID
        tappedAt = now
    }

    /// Takes the pending tap, once. `nil` when there is none or it is too old.
    func consume(now: Date = Date()) -> String? {
        defer {
            pendingPlaceID = nil
            tappedAt = nil
        }
        guard let pendingPlaceID, let tappedAt, now.timeIntervalSince(tappedAt) <= Self.tapLifetime else {
            return nil
        }
        return pendingPlaceID
    }

    /// The place id the alert carries in its `userInfo`.
    static func placeID(from userInfo: [AnyHashable: Any]) -> String? {
        guard let placeID = userInfo["placeID"] as? String, !placeID.isEmpty else { return nil }
        return placeID
    }

    /// What to open for `placeID`: the place the map loaded if there is one, otherwise the copy saved for the alert,
    /// so the place opens even when the app was started by the tap and has not fetched anything yet.
    static func place(for placeID: String, loaded: [MapPlace], saved: [ProximityPlaceSnapshot]) -> MapPlace? {
        if let place = loaded.first(where: { $0.id == placeID }) { return place }
        guard let snapshot = saved.first(where: { $0.placeID == placeID }) else { return nil }
        return MapPlace(
            id: snapshot.placeID,
            name: snapshot.name,
            latitude: snapshot.latitude,
            longitude: snapshot.longitude,
            category: .unknown,
            distanceMeters: nil,
            openingHours: snapshot.openingHours
        )
    }
}
