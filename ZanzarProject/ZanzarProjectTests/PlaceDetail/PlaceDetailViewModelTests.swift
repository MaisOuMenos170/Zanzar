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

    @Test("load populates place detail from the service")
    func loadPopulatesDetail() async {
        let mockDetail = PlaceDetail.mock(for: samplePlace)
        let service = MockPlaceDetailService(fetchResult: .success(mockDetail))
        let viewModel = PlaceDetailViewModel(place: samplePlace, service: service)

        await viewModel.load()

        #expect(viewModel.detail?.name == "Jardim Botânico")
        #expect(viewModel.detail?.totalCheckIns == 140)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == nil)
    }

    @Test("performCheckIn marks the place as checked in")
    func performCheckInUpdatesState() async {
        var mockDetail = PlaceDetail.mock(for: samplePlace)
        mockDetail.hasCheckedIn = false

        let service = MockPlaceDetailService(
            fetchResult: .success(mockDetail),
            checkInResult: .success({
                var checkedIn = mockDetail
                checkedIn.hasCheckedIn = true
                return checkedIn
            }())
        )
        let viewModel = PlaceDetailViewModel(place: samplePlace, service: service)

        await viewModel.load()
        await viewModel.performCheckIn()

        #expect(viewModel.detail?.hasCheckedIn == true)
        #expect(viewModel.isCheckingIn == false)
    }

}

final class MockPlaceDetailService: PlaceDetailServicing, @unchecked Sendable {
    var fetchResult: Result<PlaceDetail, Error>
    var checkInResult: Result<PlaceDetail, Error>?

    init(
        fetchResult: Result<PlaceDetail, Error>,
        checkInResult: Result<PlaceDetail, Error>? = nil
    ) {
        self.fetchResult = fetchResult
        self.checkInResult = checkInResult
    }

    func fetchPlaceDetail(for place: MapPlace) async throws -> PlaceDetail {
        try fetchResult.get()
    }

    func checkIn(at placeID: String) async throws -> PlaceDetail {
        guard let checkInResult else {
            fatalError("MockPlaceDetailService.checkInResult not configured")
        }
        return try checkInResult.get()
    }
}
