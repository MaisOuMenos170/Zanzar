import Testing
@testable import ZanzarProject

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
        let viewModel = PlaceDetailViewModel(
            place: samplePlace,
            userIDProvider: { "user-1" },
            userCoordinateProvider: { self.sampleUserCoordinate },
            service: service
        )

        await viewModel.load()
        await viewModel.performCheckIn()

        #expect(viewModel.detail?.hasCheckedIn == true)
        #expect(viewModel.detail?.totalCheckIns == 11)
        #expect(viewModel.isCheckingIn == false)
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

    @Test("selectReaction applies server counts after check-in")
    func selectReactionUpdatesCounts() async {
        let service = MockPlaceDetailService(
            fetchResult: .success(sampleDetail(hasCheckedIn: true)),
            reactionResult: .success(
                PlaceReactionSubmission(
                    impressionTag: ImpressionTag.delighted.rawValue,
                    impressionCounts: [ImpressionTag.delighted.rawValue: 4, ImpressionTag.happy.rawValue: 2]
                )
            )
        )
        let viewModel = PlaceDetailViewModel(
            place: samplePlace,
            userIDProvider: { "user-1" },
            userCoordinateProvider: { self.sampleUserCoordinate },
            service: service
        )

        await viewModel.load()
        await viewModel.selectReaction(ImpressionTag.delighted.rawValue)

        #expect(viewModel.detail?.selectedReactionTag == ImpressionTag.delighted.rawValue)
        #expect(viewModel.detail?.reactions.first(where: { $0.impressionTag == ImpressionTag.delighted.rawValue })?.count == 4)
        #expect(viewModel.detail?.reactions.first(where: { $0.impressionTag == ImpressionTag.happy.rawValue })?.count == 2)
    }

    @Test("selectReaction syncs counts when the user already rated")
    func selectReactionSyncsOnConflict() async {
        let service = MockPlaceDetailService(
            fetchResult: .success(sampleDetail(hasCheckedIn: true)),
            reactionResult: .failure(APIError.httpStatus(409, message: "User has already rated this place")),
            reactionSnapshot: PlaceReactionSnapshot(
                impressionCounts: [ImpressionTag.sleepy.rawValue: 3],
                selectedReactionTag: ImpressionTag.sleepy.rawValue
            )
        )
        let viewModel = PlaceDetailViewModel(
            place: samplePlace,
            userIDProvider: { "user-1" },
            userCoordinateProvider: { self.sampleUserCoordinate },
            service: service
        )

        await viewModel.load()
        await viewModel.selectReaction(ImpressionTag.delighted.rawValue)

        #expect(viewModel.detail?.selectedReactionTag == ImpressionTag.sleepy.rawValue)
        #expect(viewModel.detail?.reactions.first(where: { $0.impressionTag == ImpressionTag.sleepy.rawValue })?.count == 3)
    }
}

final class MockPlaceDetailService: PlaceDetailServicing, @unchecked Sendable {
    var fetchResult: Result<PlaceDetail, Error>
    var checkInResult: Result<Void, Error>?
    var reactionResult: Result<PlaceReactionSubmission, Error>?
    var reactionSnapshot: PlaceReactionSnapshot?
    private(set) var lastLoadContext: PlaceDetailLoadContext?

    init(
        fetchResult: Result<PlaceDetail, Error>,
        checkInResult: Result<Void, Error>? = nil,
        reactionResult: Result<PlaceReactionSubmission, Error>? = nil,
        reactionSnapshot: PlaceReactionSnapshot? = nil
    ) {
        self.fetchResult = fetchResult
        self.checkInResult = checkInResult
        self.reactionResult = reactionResult
        self.reactionSnapshot = reactionSnapshot
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

    func submitReaction(placeID: String, impressionTag: String) async throws -> PlaceReactionSubmission {
        guard let reactionResult else {
            fatalError("MockPlaceDetailService.reactionResult not configured")
        }
        return try reactionResult.get()
    }

    func fetchReactionSnapshot(placeID: String, userID: String?) async throws -> PlaceReactionSnapshot {
        guard let reactionSnapshot else {
            fatalError("MockPlaceDetailService.reactionSnapshot not configured")
        }
        return reactionSnapshot
    }
}
