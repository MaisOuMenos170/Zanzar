import Testing
@testable import ZanzarProject

@Suite("PlaceDetailViewModel")
struct PlaceDetailViewModelTests {
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
            service: service
        )

        await viewModel.load()

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
            service: service
        )

        await viewModel.load()
        await viewModel.performCheckIn()

        #expect(viewModel.detail?.hasCheckedIn == true)
        #expect(viewModel.detail?.totalCheckIns == 11)
        #expect(viewModel.isCheckingIn == false)
    }

    @Test("selectReaction updates counts after check-in")
    func selectReactionUpdatesCounts() async {
        let service = MockPlaceDetailService(
            fetchResult: .success(sampleDetail(hasCheckedIn: true)),
            reactionResult: .success(())
        )
        let viewModel = PlaceDetailViewModel(
            place: samplePlace,
            userIDProvider: { "user-1" },
            service: service
        )

        await viewModel.load()
        await viewModel.selectReaction(ImpressionTag.delighted.rawValue)

        #expect(viewModel.detail?.selectedReactionTag == ImpressionTag.delighted.rawValue)
        #expect(viewModel.detail?.reactions.first(where: { $0.impressionTag == ImpressionTag.delighted.rawValue })?.count == 1)
    }
}

final class MockPlaceDetailService: PlaceDetailServicing, @unchecked Sendable {
    var fetchResult: Result<PlaceDetail, Error>
    var checkInResult: Result<Void, Error>?
    var reactionResult: Result<Void, Error>?

    init(
        fetchResult: Result<PlaceDetail, Error>,
        checkInResult: Result<Void, Error>? = nil,
        reactionResult: Result<Void, Error>? = nil
    ) {
        self.fetchResult = fetchResult
        self.checkInResult = checkInResult
        self.reactionResult = reactionResult
    }

    func fetchPlaceDetail(context: PlaceDetailLoadContext) async throws -> PlaceDetail {
        try fetchResult.get()
    }

    func checkIn(placeID: String, userID: String) async throws {
        guard let checkInResult else {
            fatalError("MockPlaceDetailService.checkInResult not configured")
        }
        try checkInResult.get()
    }

    func submitReaction(placeID: String, userID: String, impressionTag: String) async throws {
        guard let reactionResult else {
            fatalError("MockPlaceDetailService.reactionResult not configured")
        }
        try reactionResult.get()
    }
}
