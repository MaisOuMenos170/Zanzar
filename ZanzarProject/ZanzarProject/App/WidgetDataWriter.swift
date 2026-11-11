import Foundation
import WidgetKit

/// Writes the next itinerary stop to the shared container so the iOS widget can display it.
///
/// The app and the widget extension share the App Group `group.zanzarGroup` (see both `.entitlements` files).
final class WidgetDataWriter {
    static let shared = WidgetDataWriter()

    static let appGroupID = "group.zanzarGroup"
    static let nextStopKey = "zanzar.widgetNextStop"

    private let defaults: UserDefaults?
    private var itinerary: ActiveItinerary?
    private var places: [MapPlace] = []

    private init() {
        defaults = UserDefaults(suiteName: Self.appGroupID)
    }

    func update(itinerary: ActiveItinerary?) {
        self.itinerary = itinerary
        writeNextStop()
    }

    func update(places: [MapPlace]) {
        self.places = places
        writeNextStop()
    }

    /// Writes the name of the next pending stop, or clears it when there is no active roteiro
    /// or no uncompleted stop with a known place.
    private func writeNextStop() {
        if let nextPlaceID = itinerary?.nextPendingPlaceID,
           let place = places.first(where: { $0.id == nextPlaceID }),
           let data = try? JSONEncoder().encode(WidgetNextStop(name: place.displayName)) {
            defaults?.set(data, forKey: Self.nextStopKey)
        } else {
            defaults?.removeObject(forKey: Self.nextStopKey)
        }
        WidgetCenter.shared.reloadAllTimelines()
    }
}

/// Payload written by the app so the widget can display the next stop.
private struct WidgetNextStop: Codable {
    let name: String
}
