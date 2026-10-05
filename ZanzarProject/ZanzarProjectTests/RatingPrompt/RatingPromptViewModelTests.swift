import Foundation
import os
import Testing
@testable import ZanzarProject

@MainActor
@Suite("RatingPromptViewModel")
struct RatingPromptViewModelTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)
    // ~1.1 km north of `place`, i.e. well beyond the 150 m leave distance.
    private let farAway = UserCoordinate(latitude: -25.39, longitude: -49.2)
    private let nearPlace = UserCoordinate(latitude: -25.4001, longitude: -49.2)

    private func pending(userID: String = "user-1", checkedInAgo: TimeInterval = 600) -> PendingRating {
        PendingRating(
            userID: userID,
            placeID: "place-1",
            placeName: "Jardim Botânico",
            latitude: -25.4,
            longitude: -49.2,
            checkedInAt: now.addingTimeInterval(-checkedInAgo)
        )
    }

    private func makeViewModel(
        service: MockRatingPromptService = MockRatingPromptService(),
        store: InMemoryPendingRatingStore,
        userID: String? = "user-1",
        coordinate: UserCoordinate? = nil
    ) -> RatingPromptViewModel {
        let location = coordinate ?? farAway
        let current = now
        return RatingPromptViewModel(
            service: service,
            store: store,
            userIDProvider: { userID },
            userCoordinateProvider: { location },
            now: { current }
        )
    }

    // MARK: monitorLeaving

    @Test("monitorLeaving polls the location until the user leaves the place")
    func monitorPollsUntilUserLeaves() async {
        let locationCalls = OSAllocatedUnfairLock(initialState: 0)
        let sleeps = OSAllocatedUnfairLock(initialState: 0)
        let near = nearPlace
        let far = farAway
        let current = now
        let viewModel = RatingPromptViewModel(
            service: MockRatingPromptService(hasRatedResult: .success(false)),
            store: InMemoryPendingRatingStore(stored: pending()),
            userIDProvider: { "user-1" },
            userCoordinateProvider: {
                let call = locationCalls.withLock { state -> Int in
                    state += 1
                    return state
                }
                return call < 3 ? near : far
            },
            now: { current },
            sleep: { _ in sleeps.withLock { $0 += 1 } }
        )

        await viewModel.monitorLeaving()

        #expect(viewModel.isPresented)
        #expect(sleeps.withLock { $0 } == 2)
    }

    @Test("monitorLeaving returns right away when nothing is pending")
    func monitorWithoutPending() async {
        let sleeps = OSAllocatedUnfairLock(initialState: 0)
        let current = now
        let viewModel = RatingPromptViewModel(
            service: MockRatingPromptService(),
            store: InMemoryPendingRatingStore(),
            userIDProvider: { "user-1" },
            userCoordinateProvider: { UserCoordinate(latitude: 0, longitude: 0) },
            now: { current },
            sleep: { _ in sleeps.withLock { $0 += 1 } }
        )

        await viewModel.monitorLeaving()

        #expect(viewModel.isPresented == false)
        #expect(sleeps.withLock { $0 } == 0)
    }

    @Test("monitorLeaving stops when its task is cancelled")
    func monitorStopsWhenTaskIsCancelled() async {
        let store = InMemoryPendingRatingStore(stored: pending())
        let near = nearPlace
        let current = now
        let viewModel = RatingPromptViewModel(
            service: MockRatingPromptService(),
            store: store,
            userIDProvider: { "user-1" },
            userCoordinateProvider: { near },
            now: { current },
            sleep: { try await Task.sleep(for: $0) }
        )

        let monitor = Task { await viewModel.monitorLeaving() }
        monitor.cancel()
        await monitor.value

        #expect(viewModel.isPresented == false)
        #expect(store.stored != nil)
    }

    @Test("monitorLeaving stops when the wait between polls is interrupted")
    func monitorStopsWhenSleepIsInterrupted() async {
        let store = InMemoryPendingRatingStore(stored: pending())
        let near = nearPlace
        let current = now
        let viewModel = RatingPromptViewModel(
            service: MockRatingPromptService(),
            store: store,
            userIDProvider: { "user-1" },
            userCoordinateProvider: { near },
            now: { current },
            sleep: { _ in throw CancellationError() }
        )

        await viewModel.monitorLeaving()

        #expect(viewModel.isPresented == false)
        #expect(store.stored != nil)
    }

    // MARK: refresh

    @Test("refresh does nothing without a pending rating")
    func refreshWithoutPending() async {
        let viewModel = makeViewModel(store: InMemoryPendingRatingStore())

        await viewModel.refresh()

        #expect(viewModel.isPresented == false)
    }

    @Test("refresh keeps waiting while the user is still near the place")
    func refreshWhileNearPlace() async {
        let store = InMemoryPendingRatingStore(stored: pending())
        let viewModel = makeViewModel(store: store, coordinate: nearPlace)

        await viewModel.refresh()

        #expect(viewModel.isPresented == false)
        #expect(store.stored != nil)
    }

    @Test("refresh presents the prompt once the user has left an unrated place")
    func refreshPresentsWhenFarAway() async {
        let service = MockRatingPromptService(hasRatedResult: .success(false))
        let viewModel = makeViewModel(service: service, store: InMemoryPendingRatingStore(stored: pending()))

        await viewModel.refresh()

        #expect(viewModel.isPresented)
        #expect(viewModel.pendingRating?.placeName == "Jardim Botânico")
        #expect(viewModel.selectedTag == nil)
        #expect(service.checkedPlaceIDs == ["place-1"])
    }

    @Test("refresh drops an expired pending rating")
    func refreshExpired() async {
        let store = InMemoryPendingRatingStore(
            stored: pending(checkedInAgo: RatingPromptPolicy.validityWindow + 1)
        )
        let viewModel = makeViewModel(store: store)

        await viewModel.refresh()

        #expect(viewModel.isPresented == false)
        #expect(store.stored == nil)
    }

    @Test("refresh clears the record when the place was already rated")
    func refreshAlreadyRated() async {
        let store = InMemoryPendingRatingStore(stored: pending())
        let service = MockRatingPromptService(hasRatedResult: .success(true))
        let viewModel = makeViewModel(service: service, store: store)

        await viewModel.refresh()

        #expect(viewModel.isPresented == false)
        #expect(store.stored == nil)
    }

    @Test("refresh ignores a pending rating that belongs to another user")
    func refreshOtherUser() async {
        let store = InMemoryPendingRatingStore(stored: pending(userID: "someone-else"))
        let viewModel = makeViewModel(store: store)

        await viewModel.refresh()

        #expect(viewModel.isPresented == false)
        #expect(store.stored != nil)
    }

    @Test("refresh stays silent when the rating lookup fails")
    func refreshLookupFails() async {
        let store = InMemoryPendingRatingStore(stored: pending())
        let service = MockRatingPromptService(hasRatedResult: .failure(APIError.invalidResponse))
        let viewModel = makeViewModel(service: service, store: store)

        await viewModel.refresh()

        #expect(viewModel.isPresented == false)
        #expect(store.stored != nil)
    }

    // MARK: select / submit

    private func presentedViewModel(
        service: MockRatingPromptService,
        store: InMemoryPendingRatingStore
    ) async throws -> RatingPromptViewModel {
        let viewModel = makeViewModel(service: service, store: store)
        await viewModel.refresh()
        try #require(viewModel.isPresented)
        return viewModel
    }

    @Test("select highlights the chosen emotion")
    func selectSetsTag() async throws {
        let service = MockRatingPromptService(hasRatedResult: .success(false))
        let viewModel = try await presentedViewModel(
            service: service,
            store: InMemoryPendingRatingStore(stored: pending())
        )

        viewModel.select(.happy)
        #expect(viewModel.selectedTag == .happy)

        viewModel.select(.sad)
        #expect(viewModel.selectedTag == .sad)
    }

    @Test("submit posts the selected emotion, clears the record and dismisses")
    func submitSuccess() async throws {
        let store = InMemoryPendingRatingStore(stored: pending())
        let service = MockRatingPromptService(hasRatedResult: .success(false), submitResult: .success(()))
        let viewModel = try await presentedViewModel(service: service, store: store)

        viewModel.select(.delighted)
        await viewModel.submit()

        #expect(service.submitted.map(\.placeID) == ["place-1"])
        #expect(service.submitted.map(\.tag) == [.delighted])
        #expect(viewModel.isPresented == false)
        #expect(viewModel.isSubmitting == false)
        #expect(store.stored == nil)
    }

    @Test("submit without a selection does nothing")
    func submitWithoutSelection() async throws {
        let service = MockRatingPromptService(hasRatedResult: .success(false), submitResult: .success(()))
        let viewModel = try await presentedViewModel(
            service: service,
            store: InMemoryPendingRatingStore(stored: pending())
        )

        await viewModel.submit()

        #expect(service.submitted.isEmpty)
        #expect(viewModel.isPresented)
    }

    @Test("submit treats 409 as already rated")
    func submitConflict() async throws {
        let store = InMemoryPendingRatingStore(stored: pending())
        let service = MockRatingPromptService(
            hasRatedResult: .success(false),
            submitResult: .failure(APIError.httpStatus(409, message: "User has already rated this place"))
        )
        let viewModel = try await presentedViewModel(service: service, store: store)

        viewModel.select(.happy)
        await viewModel.submit()

        #expect(viewModel.isPresented == false)
        #expect(viewModel.errorMessage == nil)
        #expect(store.stored == nil)
    }

    @Test("submit keeps the prompt open and shows the error on failure")
    func submitFailure() async throws {
        let store = InMemoryPendingRatingStore(stored: pending())
        let service = MockRatingPromptService(
            hasRatedResult: .success(false),
            submitResult: .failure(APIError.httpStatus(500, message: "Boom"))
        )
        let viewModel = try await presentedViewModel(service: service, store: store)

        viewModel.select(.sad)
        await viewModel.submit()

        #expect(viewModel.isPresented)
        #expect(viewModel.errorMessage == "Boom")
        #expect(viewModel.selectedTag == .sad)
        #expect(store.stored != nil)
    }

    @Test("dismiss clears the record so the user is asked only once")
    func dismissClearsRecord() async throws {
        let store = InMemoryPendingRatingStore(stored: pending())
        let service = MockRatingPromptService(hasRatedResult: .success(false))
        let viewModel = try await presentedViewModel(service: service, store: store)

        viewModel.dismiss()

        #expect(viewModel.isPresented == false)
        #expect(store.stored == nil)
    }
}

final class MockRatingPromptService: RatingPromptServicing, @unchecked Sendable {
    var hasRatedResult: Result<Bool, Error>
    var submitResult: Result<Void, Error>?
    private(set) var checkedPlaceIDs: [String] = []
    private(set) var submitted: [(placeID: String, tag: ImpressionTag)] = []

    init(hasRatedResult: Result<Bool, Error> = .success(false), submitResult: Result<Void, Error>? = nil) {
        self.hasRatedResult = hasRatedResult
        self.submitResult = submitResult
    }

    func hasRated(placeID: String) async throws -> Bool {
        checkedPlaceIDs.append(placeID)
        return try hasRatedResult.get()
    }

    func submitRating(placeID: String, impressionTag: ImpressionTag) async throws -> RatingSubmission {
        guard let submitResult else {
            fatalError("MockRatingPromptService.submitResult not configured")
        }
        submitted.append((placeID, impressionTag))
        try submitResult.get()
        return RatingSubmission(impressionTag: impressionTag, impressionCounts: nil)
    }
}
