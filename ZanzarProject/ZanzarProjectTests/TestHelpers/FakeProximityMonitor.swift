import Foundation
@testable import ZanzarProject

/// A `ProximityMonitoring` that only records what it was asked to watch. Tests push entries by hand.
final class FakeProximityMonitor: ProximityMonitoring {
    var isAuthorized = true
    private(set) var monitoredPlaceIDs: [String] = []
    private(set) var monitorCallCount = 0
    private(set) var stopCallCount = 0
    private(set) var lastRadius: Double?

    let entries: AsyncStream<String>
    private let continuation: AsyncStream<String>.Continuation

    init() {
        (entries, continuation) = AsyncStream.makeStream(of: String.self)
    }

    func enter(_ placeID: String) {
        continuation.yield(placeID)
    }

    func resume() async {}

    func monitor(_ places: [ProximityPlaceSnapshot], radius: Double) async {
        monitorCallCount += 1
        monitoredPlaceIDs = places.map(\.placeID)
        lastRadius = radius
    }

    func stopMonitoring() async {
        stopCallCount += 1
        monitoredPlaceIDs = []
    }
}
