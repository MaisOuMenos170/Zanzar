import Foundation
import Testing
@testable import ZanzarProject

@MainActor
@Suite("Itinerary unavailable (Figma F5)")
struct ItineraryUnavailableTests {
    @Test("a 404 means the roteiro is gone: unavailable, not a failure to retry")
    func notFoundIsUnavailable() async {
        let viewModel = ItineraryDetailViewModel(
            slug: "saiu-de-cartaz",
            service: FailingItineraryService(error: APIError.httpStatus(404, message: nil)),
            userIDProvider: { nil }
        )

        await viewModel.load()

        #expect(viewModel.isUnavailable)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.detail == nil)
    }

    @Test("any other failure keeps the retry state, and a later load clears the unavailable flag")
    func otherFailuresStayRetryable() async {
        let service = FailingItineraryService(error: APIError.httpStatus(500, message: nil))
        let viewModel = ItineraryDetailViewModel(slug: "x", service: service, userIDProvider: { nil })

        await viewModel.load()

        #expect(!viewModel.isUnavailable)
        #expect(viewModel.errorMessage != nil)

        service.error = APIError.httpStatus(404, message: nil)
        await viewModel.load()
        #expect(viewModel.isUnavailable)

        service.error = APIError.httpStatus(500, message: nil)
        await viewModel.load()
        #expect(!viewModel.isUnavailable)
    }
}

private final class FailingItineraryService: ItineraryServicing, @unchecked Sendable {
    var error: Error

    init(error: Error) { self.error = error }

    func fetchItineraries() async throws -> [Itinerary] { [] }
    func fetchItineraryDetail(slug: String) async throws -> ItineraryDetail { throw error }
    func activateItinerary(slug: String) async throws -> ActiveItinerary { throw error }
    func abandonActiveItinerary() async throws {}
    func fetchActiveItinerary(userID: String) async throws -> ActiveItinerary? { nil }
}
