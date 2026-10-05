import Testing
@testable import ZanzarProject

@MainActor
@Suite("PlaceDetailViewModel")
struct PlaceDetailViewModelTests {
    private let sampleUserCoordinate = UserCoordinate(latitude: -25.4298844, longitude: -49.2719424)

    private let samplePlace = MapPlace(
        id: "place-1",
        name: "Jardim Botânico",
        latitude: -25.4,
        longitude: -49.2,
        category: .park,
        distanceMeters: 1300
    )

    private func sampleDetail(hasCheckedIn: Bool = false, selectedReactionTag: String? = nil) -> PlaceDetail {
        PlaceDetail(
            id: samplePlace.id,
            name: samplePlace.name,
            latitude: samplePlace.latitude,
            longitude: samplePlace.longitude,
            distanceText: "1.3 km",
            openingHoursText: "Open now",
            tags: [],
            category: samplePlace.category,
            description: "Description",
            heroPhotoReference: "photo-ref",
            totalCheckIns: 10,
            reactions: ImpressionTag.reactions(from: [:], selectedTag: selectedReactionTag),
            nearbyPlaces: [],
            hasCheckedIn: hasCheckedIn,
            selectedReactionTag: selectedReactionTag
        )
    }

    @Test("load populates place detail from the service")
    func loadPopulatesDetail() async {
        let mockDetail = sampleDetail()
        let service = MockPlaceDetailService(fetchResult: .success(mockDetail))
        let viewModel = PlaceDetailViewModel(
            place: samplePlace,
            userIDProvider: { "user-1" },
            userCoordinateProvider: { self.sampleUserCoordinate },
            service: service
        )

        await viewModel.load()

        #expect(service.lastLoadContext?.userCoordinate == sampleUserCoordinate)
        #expect(viewModel.detail?.name == "Jardim Botânico")
        #expect(viewModel.detail?.totalCheckIns == 10)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == nil)
    }

    @Test("performCheckIn marks the place as checked in")
    func performCheckInUpdatesState() async {
        let service = MockPlaceDetailService(
            fetchResult: .success(sampleDetail()),
            checkInResult: .success(())
        )
        let store = InMemoryPendingRatingStore()
        let viewModel = PlaceDetailViewModel(
            place: samplePlace,
            userIDProvider: { "user-1" },
            userCoordinateProvider: { self.sampleUserCoordinate },
            service: service,
            pendingRatingStore: store
        )

        await viewModel.load()
        await viewModel.performCheckIn()

        #expect(viewModel.detail?.hasCheckedIn == true)
        #expect(viewModel.detail?.totalCheckIns == 11)
        #expect(viewModel.isCheckingIn == false)
        #expect(store.stored?.userID == "user-1")
        #expect(store.stored?.placeID == samplePlace.id)
        #expect(store.stored?.placeName == samplePlace.name)
    }

    @Test("a check-in conflict still queues a rating prompt")
    func checkInConflictQueuesRating() async throws {
        let service = MockPlaceDetailService(
            fetchResult: .success(sampleDetail()),
            checkInResult: .failure(APIError.httpStatus(409, message: nil))
        )
        let store = InMemoryPendingRatingStore()
        let viewModel = PlaceDetailViewModel(
            place: samplePlace,
            userIDProvider: { "user-1" },
            userCoordinateProvider: { self.sampleUserCoordinate },
            service: service,
            pendingRatingStore: store
        )

        await viewModel.load()
        await viewModel.performCheckIn()

        #expect(viewModel.detail?.hasCheckedIn == true)
        let queued = try #require(store.stored)
        #expect(queued.userID == "user-1")
        #expect(queued.placeID == viewModel.detail?.id)
    }

    @Test("load omits nearby places when user location is unavailable")
    func loadOmitsNearbyPlacesWithoutUserLocation() async {
        let service = MockPlaceDetailService(fetchResult: .success(sampleDetail()))
        let viewModel = PlaceDetailViewModel(
            place: samplePlace,
            userIDProvider: { "user-1" },
            userCoordinateProvider: { throw LocationMapError.locationUnavailable },
            service: service
        )

        await viewModel.load()

        #expect(service.lastLoadContext?.userCoordinate == nil)
        #expect(viewModel.detail?.name == "Jardim Botânico")
    }
}

final class MockPlaceDetailService: PlaceDetailServicing, @unchecked Sendable {
    var fetchResult: Result<PlaceDetail, Error>
    var checkInResult: Result<Void, Error>?
    private(set) var lastLoadContext: PlaceDetailLoadContext?

    init(
        fetchResult: Result<PlaceDetail, Error>,
        checkInResult: Result<Void, Error>? = nil
    ) {
        self.fetchResult = fetchResult
        self.checkInResult = checkInResult
    }

    func fetchPlaceDetail(context: PlaceDetailLoadContext) async throws -> PlaceDetail {
        lastLoadContext = context
        return try fetchResult.get()
    }

    func checkIn(placeID: String) async throws {
        guard let checkInResult else {
            fatalError("MockPlaceDetailService.checkInResult not configured")
        }
        try checkInResult.get()
    }
}
