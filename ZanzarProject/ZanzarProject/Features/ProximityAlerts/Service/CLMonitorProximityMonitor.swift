import CoreLocation
import Foundation

/// Region monitoring on top of `CLMonitor`. iOS keeps the circles and relaunches the app in the background when the
/// user walks into one; `resume()` has to run at that launch so the event reaches `entries`.
final class CLMonitorProximityMonitor: ProximityMonitoring {
    let entries: AsyncStream<String>
    private let continuation: AsyncStream<String>.Continuation
    private let manager = CLLocationManager()
    private var monitor: CLMonitor?
    private var eventsTask: Task<Void, Never>?

    var isAuthorized: Bool {
        manager.authorizationStatus == .authorizedAlways
    }

    init() {
        (entries, continuation) = AsyncStream.makeStream(of: String.self)
    }

    func resume() async {
        _ = await activeMonitor()
    }

    func monitor(_ places: [ProximityPlaceSnapshot], radius: Double) async {
        let monitor = await activeMonitor()
        let wanted = Set(places.map(\.placeID))
        for identifier in await monitor.identifiers where !wanted.contains(identifier) {
            await monitor.remove(identifier)
        }
        let already = Set(await monitor.identifiers)
        for place in places where !already.contains(place.placeID) {
            let center = CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude)
            let condition = CLMonitor.CircularGeographicCondition(center: center, radius: radius)
            await monitor.add(condition, identifier: place.placeID, assuming: .unsatisfied)
        }
    }

    func stopMonitoring() async {
        guard let monitor else { return }
        for identifier in await monitor.identifiers {
            await monitor.remove(identifier)
        }
    }

    private func activeMonitor() async -> CLMonitor {
        if let monitor { return monitor }
        // The name must be letters and digits only: `CLMonitor` asserts otherwise, which kills the app.
        let created = await CLMonitor("ProximityAlerts")
        // Another caller may have created it while this one was suspended.
        if let monitor { return monitor }
        monitor = created
        let continuation = continuation
        eventsTask = Task {
            do {
                for try await event in await created.events where event.state == .satisfied {
                    continuation.yield(event.identifier)
                }
            } catch {
                AppLog.proximity.error("Region events ended", error: error)
            }
        }
        return created
    }
}
