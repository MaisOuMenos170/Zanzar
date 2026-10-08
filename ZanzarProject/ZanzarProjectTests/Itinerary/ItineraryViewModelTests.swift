import Foundation
import Testing
@testable import ZanzarProject

@MainActor
@Suite("Itinerary view models")
struct ItineraryViewModelTests {
    private static let sampleItinerary = Itinerary(
        slug: "centro-historico",
        name: "Centro Histórico",
        category: "historic",
        routeType: .fixed,
        placesCount: 2,
        completedCount: 42,
        coverImageURL: nil
    )

    private static let sampleDetail = ItineraryDetail(
        slug: "centro-historico",
        name: "Centro Histórico",
        description: "Passeio histórico",
        category: "historic",
        routeType: .fixed,
        objectives: ["História"],
        targetCategory: nil,
        targetCount: nil,
        placesCount: 2,
        completedCount: 42,
        coverImageURL: nil,
        places: [
            ItineraryDetailPlace(placeID: "ChIJ1", name: "Paço", latitude: -25.43, longitude: -49.27)
        ]
    )

    private static let sampleActive = ActiveItinerary(
        templateID: "674abc",
        slug: "centro-historico",
        name: "Centro Histórico",
        description: "",
        category: "historic",
        routeType: .fixed,
        objectives: [],
        targetCategory: nil,
        targetCount: nil,
        startedAt: .now,
        places: [
            ItinerarySlot(id: "1", placeID: "ChIJ1", placeName: "Paço", isCompleted: true, completedAt: .now, stampID: nil)
        ]
    )

    // MARK: - List

    @Test("load fetches itineraries, nearby places, and active progress")
    func listLoadSuccess() async {
        let itineraryService = MockItineraryService(
            itinerariesResult: .success([Self.sampleItinerary]),
            activeItineraryResult: .success(Self.sampleActive)
        )
        let locationService = MockLocationMapService()
        locationService.locationResult = .success(DevLocation.pucPr)
        locationService.placesResult = .success([
            MapPlace(
                id: "ChIJ9",
                name: "Parque",
                latitude: -25.43,
                longitude: -49.27,
                category: .park,
                distanceMeters: 120
            )
        ])
        let viewModel = ItineraryListViewModel(
            itineraryService: itineraryService,
            locationService: locationService,
            userIDProvider: { "user-1" }
        )

        await viewModel.load()

        #expect(viewModel.itineraries == [Self.sampleItinerary])
        #expect(viewModel.activeItinerary == Self.sampleActive)
        #expect(viewModel.nearbyPlaces.count == 1)
        #expect(viewModel.errorMessage == nil)
        #expect(itineraryService.fetchActiveItineraryUserID == "user-1")
    }

    @Test("load keeps itineraries when active itinerary fetch fails")
    func listLoadActiveFailure() async {
        let itineraryService = MockItineraryService(
            itinerariesResult: .success([Self.sampleItinerary]),
            activeItineraryResult: .failure(APIError.invalidResponse)
        )
        let viewModel = ItineraryListViewModel(
            itineraryService: itineraryService,
            locationService: MockLocationMapService.nearbyUnavailable(),
            userIDProvider: { "user-1" }
        )

        await viewModel.load()

        #expect(viewModel.itineraries == [Self.sampleItinerary])
        #expect(viewModel.activeItinerary == nil)
        #expect(viewModel.errorMessage == nil)
    }

    @Test("abandon clears the active itinerary card")
    func listAbandon() async {
        let itineraryService = MockItineraryService(
            itinerariesResult: .success([]),
            activeItineraryResult: .success(Self.sampleActive)
        )
        let viewModel = ItineraryListViewModel(
            itineraryService: itineraryService,
            locationService: MockLocationMapService.nearbyUnavailable(),
            userIDProvider: { "user-1" }
        )
        await viewModel.load()

        await viewModel.abandonActiveItinerary()

        #expect(itineraryService.abandonCount == 1)
        #expect(viewModel.activeItinerary == nil)
    }

    @Test("abandon failure exposes an action error message")
    func listAbandonFailure() async {
        let itineraryService = MockItineraryService(
            itinerariesResult: .success([]),
            activeItineraryResult: .success(Self.sampleActive)
        )
        itineraryService.abandonError = APIError.invalidResponse
        let viewModel = ItineraryListViewModel(
            itineraryService: itineraryService,
            locationService: MockLocationMapService.nearbyUnavailable(),
            userIDProvider: { "user-1" }
        )
        await viewModel.load()

        await viewModel.abandonActiveItinerary()

        #expect(viewModel.activeItinerary == Self.sampleActive)
        #expect(viewModel.actionErrorMessage == String(localized: "itinerary.detail.actionError.generic"))
        #expect(viewModel.showsActionError)
        viewModel.showsActionError = false
        #expect(viewModel.actionErrorMessage == nil)
        #expect(viewModel.showsActionError == false)
    }

    // MARK: - Detail

    @Test("activate succeeds and stores the active itinerary")
    func detailActivateSuccess() async {
        let itineraryService = MockItineraryService(
            detailResult: .success(Self.sampleDetail),
            activateResult: .success(Self.sampleActive)
        )
        let viewModel = ItineraryDetailViewModel(
            slug: "centro-historico",
            service: itineraryService,
            userIDProvider: { "user-1" }
        )
        await viewModel.load()

        let succeeded = await viewModel.activateItinerary()

        #expect(succeeded)
        #expect(viewModel.activeItinerary == Self.sampleActive)
        #expect(itineraryService.lastActivatedSlug == "centro-historico")
        #expect(viewModel.actionErrorMessage == nil)
    }

    @Test("activate reports a friendly message when another route is already active")
    func detailActivateConflict() async {
        let itineraryService = MockItineraryService(
            detailResult: .success(Self.sampleDetail),
            activateResult: .failure(APIError.httpStatus(409, message: "User already has an active itinerary"))
        )
        let viewModel = ItineraryDetailViewModel(
            slug: "centro-historico",
            service: itineraryService,
            userIDProvider: { "user-1" }
        )
        await viewModel.load()

        let succeeded = await viewModel.activateItinerary()

        #expect(!succeeded)
        #expect(viewModel.actionErrorMessage == String(localized: "itinerary.detail.actionError.alreadyActive"))
    }

    @Test("abandon clears the active itinerary on the detail screen")
    func detailAbandon() async {
        let itineraryService = MockItineraryService(
            detailResult: .success(Self.sampleDetail),
            activeItineraryResult: .success(Self.sampleActive)
        )
        let viewModel = ItineraryDetailViewModel(
            slug: "centro-historico",
            service: itineraryService,
            userIDProvider: { "user-1" }
        )
        await viewModel.load()

        let succeeded = await viewModel.abandonItinerary()

        #expect(succeeded)
        #expect(viewModel.activeItinerary == nil)
        #expect(itineraryService.abandonCount == 1)
    }
}

final class MockItineraryService: ItineraryServicing, @unchecked Sendable {
    var itinerariesResult: Result<[Itinerary], Error>
    var detailResult: Result<ItineraryDetail, Error>
    var activateResult: Result<ActiveItinerary, Error>
    var activeItineraryResult: Result<ActiveItinerary?, Error>
    var abandonError: Error?

    private(set) var lastActivatedSlug: String?
    private(set) var fetchActiveItineraryUserID: String?
    private(set) var abandonCount = 0

    init(
        itinerariesResult: Result<[Itinerary], Error> = .success([]),
        detailResult: Result<ItineraryDetail, Error> = .failure(APIError.invalidResponse),
        activateResult: Result<ActiveItinerary, Error> = .failure(APIError.invalidResponse),
        activeItineraryResult: Result<ActiveItinerary?, Error> = .success(nil)
    ) {
        self.itinerariesResult = itinerariesResult
        self.detailResult = detailResult
        self.activateResult = activateResult
        self.activeItineraryResult = activeItineraryResult
    }

    func fetchItineraries() async throws -> [Itinerary] {
        try itinerariesResult.get()
    }

    func fetchItineraryDetail(slug: String) async throws -> ItineraryDetail {
        _ = slug
        return try detailResult.get()
    }

    func activateItinerary(slug: String) async throws -> ActiveItinerary {
        lastActivatedSlug = slug
        return try activateResult.get()
    }

    func abandonActiveItinerary() async throws {
        abandonCount += 1
        if let abandonError { throw abandonError }
    }

    func fetchActiveItinerary(userID: String) async throws -> ActiveItinerary? {
        fetchActiveItineraryUserID = userID
        return try activeItineraryResult.get()
    }
}
