import Foundation
import Testing
@testable import ZanzarProject

@MainActor
@Suite("ItineraryDetailViewModel")
struct ItineraryDetailViewModelTests {
    private static let otherActive = ActiveItinerary(
        templateID: "674abc",
        slug: "visitando-parques",
        name: "Parques",
        description: "",
        category: "park",
        routeType: .free,
        objectives: [],
        targetCategory: .park,
        targetCount: 3,
        startedAt: .now,
        places: []
    )

    @Test("isCurrentItineraryActive is true when slugs match")
    func currentItineraryActive() async {
        let service = DetailOnlyMockItineraryService(activeItinerary: Self.otherActive)
        let viewModel = ItineraryDetailViewModel(
            slug: "visitando-parques",
            service: service,
            userIDProvider: { "user-1" }
        )
        await viewModel.load()

        #expect(viewModel.isCurrentItineraryActive)
        #expect(!viewModel.hasDifferentActiveItinerary)
    }

    @Test("hasDifferentActiveItinerary when another slug is active")
    func differentActiveItinerary() async {
        let service = DetailOnlyMockItineraryService(activeItinerary: Self.otherActive)
        let viewModel = ItineraryDetailViewModel(
            slug: "centro-historico",
            service: service,
            userIDProvider: { "user-1" }
        )
        await viewModel.load()

        #expect(!viewModel.isCurrentItineraryActive)
        #expect(viewModel.hasDifferentActiveItinerary)
    }
}

@MainActor
private final class DetailOnlyMockItineraryService: ItineraryServicing, @unchecked Sendable {
    private let activeItinerary: ActiveItinerary?

    init(activeItinerary: ActiveItinerary?) {
        self.activeItinerary = activeItinerary
    }

    func fetchItineraries() async throws -> [Itinerary] { [] }

    func fetchItineraryDetail(slug: String) async throws -> ItineraryDetail {
        ItineraryDetail(
            slug: slug,
            name: slug,
            description: "",
            category: "historic",
            routeType: .fixed,
            objectives: [],
            targetCategory: nil,
            targetCount: nil,
            placesCount: 1,
            completedCount: 0,
            coverImageURL: nil,
            places: []
        )
    }

    func activateItinerary(slug: String) async throws -> ActiveItinerary {
        throw APIError.invalidResponse
    }

    func abandonActiveItinerary() async throws {}

    func fetchActiveItinerary(userID: String) async throws -> ActiveItinerary? {
        activeItinerary
    }
}
