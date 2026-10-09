import Testing
@testable import ZanzarProject

@MainActor
@Suite("PlaceDetailViewModel")
struct PlaceDetailViewModelTests {
    private let sampleUserCoordinate = UserCoordinate(latitude: -25.4298844, longitude: -49.2719424)
    private let nearbyUserCoordinate = UserCoordinate(latitude: -25.4, longitude: -49.2, accuracyMeters: 12)

    private let samplePlace = MapPlace(
        id: "place-1",
        name: "Jardim Botânico",
        latitude: -25.4,
        longitude: -49.2,
        category: .park,
        distanceMeters: 1300
    )

    private let sampleCheckInResult = CheckInResult(
        stampID: "stamp_park",
        isNewStamp: true,
        completedItinerarySlots: 1,
        totalItinerarySlots: 3,
        isItineraryCompleted: false
    )

    private func sampleDetail(
        hasCheckedIn: Bool = false,
        isInActiveItinerary: Bool = false,
        selectedReactionTag: String? = nil
    ) -> PlaceDetail {
        PlaceDetail(
            id: samplePlace.id,
            name: samplePlace.name,
            nickname: nil,
            latitude: samplePlace.latitude,
            longitude: samplePlace.longitude,
            distanceText: "1.3 km",
            openingHoursText: "Open now",
            tags: [],
            category: .park,
            description: "Description",
            heroPhotoReference: "photo-ref",
            totalCheckIns: 10,
            reactions: ImpressionTag.reactions(from: [:], selectedTag: selectedReactionTag),
            nearbyPlaces: [],
            hasCheckedIn: hasCheckedIn,
            isInActiveItinerary: isInActiveItinerary,
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

    @Test("requestCheckIn opens confirmation without calling the API")
    func requestCheckInShowsConfirmation() async {
        let service = MockPlaceDetailService(fetchResult: .success(sampleDetail()))
        let viewModel = PlaceDetailViewModel(
            place: samplePlace,
            userIDProvider: { "user-1" },
            userCoordinateProvider: { self.sampleUserCoordinate },
            service: service
        )
        await viewModel.load()

        viewModel.requestCheckIn()

        #expect(viewModel.showsCheckInConfirmation)
    }

    @Test("confirmCheckIn marks the place as checked in and shows a new seal")
    func confirmCheckInUpdatesState() async {
        let service = MockPlaceDetailService(
            fetchResult: .success(sampleDetail()),
            checkInResult: .success(sampleCheckInResult)
        )
        let store = InMemoryPendingRatingStore()
        let viewModel = PlaceDetailViewModel(
            place: samplePlace,
            userIDProvider: { "user-1" },
            userCoordinateProvider: { self.nearbyUserCoordinate },
            service: service,
            pendingRatingStore: store
        )

        await viewModel.load()
        await viewModel.confirmCheckIn()

        #expect(service.checkInCalls.map(\.coordinate) == [self.nearbyUserCoordinate])
        #expect(viewModel.detail?.hasCheckedIn == true)
        #expect(viewModel.detail?.totalCheckIns == 11)
        #expect(viewModel.isCheckingIn == false)
        #expect(viewModel.earnedSealPresentation?.placeName == "Jardim Botânico")
        #expect(viewModel.earnedSealPresentation?.category == .park)
        #expect(viewModel.showsCompletedItineraryAlert == false)
        #expect(store.stored?.userID == "user-1")
        #expect(store.stored?.placeID == samplePlace.id)
    }

    @Test("a repeated category stamp does not show the earned seal alert")
    func repeatedStampSkipsAlert() async {
        let repeatedResult = CheckInResult(
            stampID: "stamp_park",
            isNewStamp: false,
            completedItinerarySlots: 2,
            totalItinerarySlots: 3,
            isItineraryCompleted: false
        )
        let service = MockPlaceDetailService(
            fetchResult: .success(sampleDetail()),
            checkInResult: .success(repeatedResult)
        )
        let viewModel = PlaceDetailViewModel(
            place: samplePlace,
            userIDProvider: { "user-1" },
            userCoordinateProvider: { self.nearbyUserCoordinate },
            service: service
        )

        await viewModel.load()
        await viewModel.confirmCheckIn()

        #expect(viewModel.detail?.hasCheckedIn == true)
        #expect(viewModel.earnedSealPresentation == nil)
        #expect(viewModel.showsCompletedItineraryAlert == false)
    }

    @Test("completing an itinerary without a new stamp shows the completion alert")
    func completedItineraryShowsAlert() async {
        let completedResult = CheckInResult(
            stampID: "stamp_park",
            isNewStamp: false,
            completedItinerarySlots: 3,
            totalItinerarySlots: 3,
            isItineraryCompleted: true
        )
        let service = MockPlaceDetailService(
            fetchResult: .success(sampleDetail()),
            checkInResult: .success(completedResult)
        )
        let viewModel = PlaceDetailViewModel(
            place: samplePlace,
            userIDProvider: { "user-1" },
            userCoordinateProvider: { self.nearbyUserCoordinate },
            service: service
        )

        await viewModel.load()
        await viewModel.confirmCheckIn()

        #expect(viewModel.earnedSealPresentation == nil)
        #expect(viewModel.showsCompletedItineraryAlert)
        viewModel.dismissCompletedItineraryAlert()
        #expect(viewModel.showsCompletedItineraryAlert == false)
    }

    @Test("a new seal is shown before the itinerary completion alert")
    func completedItineraryWaitsForSealDismiss() async {
        let completedWithSeal = CheckInResult(
            stampID: "stamp_park",
            isNewStamp: true,
            completedItinerarySlots: 3,
            totalItinerarySlots: 3,
            isItineraryCompleted: true
        )
        let service = MockPlaceDetailService(
            fetchResult: .success(sampleDetail()),
            checkInResult: .success(completedWithSeal)
        )
        let viewModel = PlaceDetailViewModel(
            place: samplePlace,
            userIDProvider: { "user-1" },
            userCoordinateProvider: { self.nearbyUserCoordinate },
            service: service
        )

        await viewModel.load()
        await viewModel.confirmCheckIn()

        #expect(viewModel.earnedSealPresentation?.category == .park)
        #expect(viewModel.showsCompletedItineraryAlert == false)

        viewModel.dismissEarnedSealAlert()

        #expect(viewModel.earnedSealPresentation == nil)
        #expect(viewModel.showsCompletedItineraryAlert)
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
            userCoordinateProvider: { self.nearbyUserCoordinate },
            service: service,
            pendingRatingStore: store
        )

        await viewModel.load()
        await viewModel.confirmCheckIn()

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

    @Test("confirmCheckIn refuses a far location without calling the API")
    func confirmCheckInRejectsFarLocation() async {
        let service = MockPlaceDetailService(
            fetchResult: .success(sampleDetail()),
            checkInResult: .success(sampleCheckInResult)
        )
        let viewModel = PlaceDetailViewModel(
            place: samplePlace,
            userIDProvider: { "user-1" },
            userCoordinateProvider: {
                UserCoordinate(
                    latitude: self.sampleUserCoordinate.latitude,
                    longitude: self.sampleUserCoordinate.longitude,
                    accuracyMeters: 12
                )
            },
            service: service
        )

        await viewModel.load()
        await viewModel.confirmCheckIn()

        #expect(service.checkInCalls.isEmpty)
        #expect(viewModel.checkInWarning == .tooFar)
        #expect(viewModel.detail?.hasCheckedIn == false)
        #expect(viewModel.errorMessage == nil)
    }

    @Test("a 422 from the server shows the too-far warning")
    func confirmCheckInMapsServerRejectionToTooFar() async {
        let service = MockPlaceDetailService(
            fetchResult: .success(sampleDetail()),
            checkInResult: .failure(APIError.httpStatus(422, message: "Check-in is too far from the place"))
        )
        let viewModel = PlaceDetailViewModel(
            place: samplePlace,
            userIDProvider: { "user-1" },
            userCoordinateProvider: { self.nearbyUserCoordinate },
            service: service
        )

        await viewModel.load()
        await viewModel.confirmCheckIn()

        #expect(service.checkInCalls.count == 1)
        #expect(viewModel.checkInWarning == .tooFar)
        #expect(viewModel.detail?.hasCheckedIn == false)
        #expect(viewModel.errorMessage == nil)
    }

    @Test("confirmCheckIn warns when location is unavailable")
    func confirmCheckInRequiresLocation() async {
        let service = MockPlaceDetailService(
            fetchResult: .success(sampleDetail()),
            checkInResult: .success(sampleCheckInResult)
        )
        let viewModel = PlaceDetailViewModel(
            place: samplePlace,
            userIDProvider: { "user-1" },
            userCoordinateProvider: { throw LocationMapError.locationUnavailable },
            service: service
        )

        await viewModel.load()
        await viewModel.confirmCheckIn()

        #expect(service.checkInCalls.isEmpty)
        #expect(viewModel.checkInWarning == .locationRequired)
        #expect(viewModel.detail?.hasCheckedIn == false)
    }

    @Test("confirmCheckIn warns when the location fix is too coarse")
    func confirmCheckInRejectsUncertainLocation() async {
        let service = MockPlaceDetailService(
            fetchResult: .success(sampleDetail()),
            checkInResult: .success(sampleCheckInResult)
        )
        let viewModel = PlaceDetailViewModel(
            place: samplePlace,
            userIDProvider: { "user-1" },
            userCoordinateProvider: {
                UserCoordinate(latitude: -25.4, longitude: -49.2, accuracyMeters: 400)
            },
            service: service
        )

        await viewModel.load()
        await viewModel.confirmCheckIn()

        #expect(service.checkInCalls.isEmpty)
        #expect(viewModel.checkInWarning == .locationUncertain)
        #expect(viewModel.detail?.hasCheckedIn == false)
    }
}

final class MockPlaceDetailService: PlaceDetailServicing, @unchecked Sendable {
    var fetchResult: Result<PlaceDetail, Error>
    var checkInResult: Result<CheckInResult, Error>?
    private(set) var lastLoadContext: PlaceDetailLoadContext?
    private(set) var checkInCalls: [(placeID: String, coordinate: UserCoordinate)] = []

    init(
        fetchResult: Result<PlaceDetail, Error>,
        checkInResult: Result<CheckInResult, Error>? = nil
    ) {
        self.fetchResult = fetchResult
        self.checkInResult = checkInResult
    }

    func fetchPlaceDetail(context: PlaceDetailLoadContext) async throws -> PlaceDetail {
        lastLoadContext = context
        return try fetchResult.get()
    }

    func checkIn(placeID: String, coordinate: UserCoordinate) async throws -> CheckInResult {
        checkInCalls.append((placeID, coordinate))
        guard let checkInResult else {
            fatalError("MockPlaceDetailService.checkInResult not configured")
        }
        return try checkInResult.get()
    }
}
