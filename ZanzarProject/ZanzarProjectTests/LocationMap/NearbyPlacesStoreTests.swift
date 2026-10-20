import CoreLocation
import Foundation
import Testing
@testable import ZanzarProject

@MainActor
@Suite("NearbyPlacesStore")
struct NearbyPlacesStoreTests {
    private static let origin = UserCoordinate(latitude: -25.4290, longitude: -49.2720)
    /// About 330 m north of `origin`.
    private static let farAway = UserCoordinate(latitude: -25.4260, longitude: -49.2720)
    /// About 55 m north of `origin`.
    private static let nearby = UserCoordinate(latitude: -25.42850, longitude: -49.2720)

    private static let place = MapPlace(
        id: "p1",
        name: "Parque",
        latitude: -25.43,
        longitude: -49.27,
        category: .park,
        distanceMeters: 120
    )

    private func makeStore(clock: TestClock = TestClock()) -> (NearbyPlacesStore, MockLocationMapService) {
        let service = MockLocationMapService()
        service.locationResult = .success(Self.origin)
        service.placesResult = .success([Self.place])
        return (NearbyPlacesStore(service: service, now: { clock.date }), service)
    }

    @Test("the first refresh fetches; later calls inside the window do not touch the server")
    func freshDataSkipsTheServer() async throws {
        let (store, service) = makeStore()

        try await store.refreshIfNeeded()
        try await store.refreshIfNeeded()

        #expect(store.places == [Self.place])
        #expect(store.userCoordinate == Self.origin)
        #expect(service.fetchCount == 1)
    }

    @Test("data older than the window is fetched again")
    func expiredDataIsRefetched() async throws {
        let clock = TestClock()
        let (store, service) = makeStore(clock: clock)
        try await store.refreshIfNeeded()

        clock.advance(by: 119)
        try await store.refreshIfNeeded()
        #expect(service.fetchCount == 1)

        clock.advance(by: 2)
        try await store.refreshIfNeeded()
        #expect(service.fetchCount == 2)
    }

    @Test("a dirty store is fetched again even when the data is fresh")
    func dirtyDataIsRefetched() async throws {
        let (store, service) = makeStore()
        try await store.refreshIfNeeded()

        store.markDirty()
        try await store.refreshIfNeeded()
        try await store.refreshIfNeeded()

        #expect(service.fetchCount == 2)
    }

    @Test("walking more than the minimum distance refetches; a short walk does not")
    func movementRefetches() async throws {
        let (store, service) = makeStore()
        try await store.refreshIfNeeded()

        service.locationResult = .success(Self.nearby)
        try await store.refreshIfNeeded()
        #expect(service.fetchCount == 1)

        service.locationResult = .success(Self.farAway)
        try await store.refreshIfNeeded()
        #expect(service.fetchCount == 2)
        #expect(store.userCoordinate == Self.farAway)
    }

    @Test("an unavailable position never forces a refetch of fresh data")
    func unavailablePositionKeepsFreshData() async throws {
        let (store, service) = makeStore()
        try await store.refreshIfNeeded()

        service.locationResult = .failure(LocationMapError.locationUnavailable)
        try await store.refreshIfNeeded()

        #expect(service.fetchCount == 1)
        #expect(store.places == [Self.place])
    }

    @Test("refresh always fetches")
    func refreshAlwaysFetches() async throws {
        let (store, service) = makeStore()
        try await store.refreshIfNeeded()

        try await store.refresh()

        #expect(service.fetchCount == 2)
    }

    @Test("callers that arrive together share one fetch")
    func concurrentCallersShareOneFetch() async throws {
        let service = SuspendingLocationMapService()
        let store = NearbyPlacesStore(service: service)

        async let first: Void = store.refreshIfNeeded()
        async let second: Void = store.refreshIfNeeded()
        async let third: Void = store.refresh()
        _ = try await (first, second, third)

        #expect(service.fetchCount == 1)
        #expect(store.places.count == 1)
    }

    @Test("a failed fetch keeps the old places and is retried by the next call")
    func failedFetchIsRetried() async throws {
        let (store, service) = makeStore()
        try await store.refreshIfNeeded()

        service.placesResult = .failure(URLError(.notConnectedToInternet))
        store.markDirty()
        await #expect(throws: URLError.self) {
            try await store.refreshIfNeeded()
        }
        #expect(store.places == [Self.place])

        service.placesResult = .success([])
        try await store.refreshIfNeeded()
        #expect(store.places.isEmpty)
        #expect(service.fetchCount == 3)
    }

    @Test("a location failure on the first load is thrown to the caller")
    func locationFailureIsThrown() async {
        let service = MockLocationMapService()
        service.locationResult = .failure(LocationMapError.authorizationDenied)
        let store = NearbyPlacesStore(service: service)

        await #expect(throws: LocationMapError.self) {
            try await store.refreshIfNeeded()
        }
        #expect(store.places.isEmpty)
        #expect(service.fetchCount == 0)
    }
}

/// Yields inside the fetch so every concurrent caller has joined before it can finish.
@MainActor
private final class SuspendingLocationMapService: LocationMapServicing {
    private(set) var fetchCount = 0

    func currentUserLocation() async throws -> UserCoordinate {
        await Task.yield()
        return UserCoordinate(latitude: -25.429, longitude: -49.272)
    }

    func fetchNearbyPlaces(from coordinate: UserCoordinate) async throws -> [MapPlace] {
        fetchCount += 1
        for _ in 0..<5 {
            await Task.yield()
        }
        return [
            MapPlace(
                id: "p1",
                name: "Parque",
                latitude: -25.43,
                longitude: -49.27,
                category: .park,
                distanceMeters: 120
            )
        ]
    }
}
