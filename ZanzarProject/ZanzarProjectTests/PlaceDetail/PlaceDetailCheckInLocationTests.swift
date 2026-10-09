import Testing
@testable import ZanzarProject

@MainActor
@Suite("PlaceDetailViewModel check-in location")
struct PlaceDetailCheckInLocationTests {
    @Test("confirmCheckIn refuses a far location without calling the API")
    func confirmCheckInRejectsFarLocation() async {
        let service = MockPlaceDetailService(
            fetchResult: .success(PlaceDetailFixture.detail()),
            checkInResult: .success(PlaceDetailFixture.checkInResult)
        )
        let viewModel = PlaceDetailViewModel(
            place: PlaceDetailFixture.place,
            userIDProvider: { "user-1" },
            userCoordinateProvider: {
                UserCoordinate(
                    latitude: PlaceDetailFixture.userCoordinate.latitude,
                    longitude: PlaceDetailFixture.userCoordinate.longitude,
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
            fetchResult: .success(PlaceDetailFixture.detail()),
            checkInResult: .failure(APIError.httpStatus(422, message: "Check-in is too far from the place"))
        )
        let viewModel = PlaceDetailViewModel(
            place: PlaceDetailFixture.place,
            userIDProvider: { "user-1" },
            userCoordinateProvider: { PlaceDetailFixture.nearbyUserCoordinate },
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
            fetchResult: .success(PlaceDetailFixture.detail()),
            checkInResult: .success(PlaceDetailFixture.checkInResult)
        )
        let viewModel = PlaceDetailViewModel(
            place: PlaceDetailFixture.place,
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
            fetchResult: .success(PlaceDetailFixture.detail()),
            checkInResult: .success(PlaceDetailFixture.checkInResult)
        )
        let viewModel = PlaceDetailViewModel(
            place: PlaceDetailFixture.place,
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
