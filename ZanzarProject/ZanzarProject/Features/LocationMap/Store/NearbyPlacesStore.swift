import CoreLocation
import Foundation
import Observation

/// The single source of the places around the user. The map, the itinerary tab and the place detail
/// all read from here instead of each calling `GET /places`.
///
/// Callers use `refreshIfNeeded()`, which only goes to the server when the data is missing, older than
/// `maxAge`, was fetched far from where the user is now, or was marked dirty (a check-in or an itinerary
/// change altered the pins). Concurrent callers share one in-flight fetch.
@Observable
final class NearbyPlacesStore {
    private let service: LocationMapServicing
    private let now: () -> Date

    private(set) var places: [MapPlace] = []
    /// The latest known position of the user; updated by every location read, fetch or not.
    private(set) var userCoordinate: UserCoordinate?
    private(set) var lastFetchedAt: Date?
    private(set) var isLoading = false

    private var lastFetchCoordinate: UserCoordinate?
    private var isDirty = false
    private var inFlight: Task<Void, Error>?

    init(service: LocationMapServicing = LocationMapService(), now: @escaping () -> Date = { Date() }) {
        self.service = service
        self.now = now
    }

    /// Flags the places as outdated, e.g. after a check-in. The next `refreshIfNeeded()` fetches them.
    func markDirty() {
        isDirty = true
    }

    /// Fetches only when the data is stale; otherwise returns without touching the network.
    /// Throws `LocationMapError` when the position is unavailable and the network error when the fetch fails.
    func refreshIfNeeded(
        maxAge: Duration = DataFreshness.placesMaxAge,
        minMovement: CLLocationDistance = DataFreshness.minMovement
    ) async throws {
        if let inFlight {
            try await inFlight.value
            return
        }
        guard let lastFetchedAt, !isDirty else {
            try await refresh()
            return
        }
        if now().timeIntervalSince(lastFetchedAt) > maxAge / .seconds(1) {
            try await refresh()
            return
        }
        // Fresh by age: only a long walk makes it stale. An unavailable position is not a reason to refetch.
        guard let current = try? await service.currentUserLocation() else { return }
        userCoordinate = current
        if let base = lastFetchCoordinate, Self.distance(from: base, to: current) > minMovement {
            try await refresh()
        }
    }

    /// Always fetches (pull-to-refresh, retry after an error). A fetch already in flight is awaited instead
    /// of starting a second one.
    func refresh() async throws {
        if let inFlight {
            try await inFlight.value
            return
        }
        // Cleared before the request so a `markDirty()` made while it runs is not lost.
        isDirty = false
        isLoading = true
        // Unstructured on purpose: the fetch is shared, so it must outlive the view task that started it
        // (which SwiftUI cancels when the view disappears) and finish for the callers still waiting.
        let task = Task {
            defer {
                inFlight = nil
                isLoading = false
            }
            do {
                let coordinate = try await service.currentUserLocation()
                userCoordinate = coordinate
                let fetched = try await service.fetchNearbyPlaces(from: coordinate)
                places = fetched
                lastFetchCoordinate = coordinate
                lastFetchedAt = now()
            } catch {
                isDirty = true
                throw error
            }
        }
        inFlight = task
        try await task.value
    }

    private static func distance(from start: UserCoordinate, to end: UserCoordinate) -> CLLocationDistance {
        CLLocation(latitude: start.latitude, longitude: start.longitude)
            .distance(from: CLLocation(latitude: end.latitude, longitude: end.longitude))
    }
}
