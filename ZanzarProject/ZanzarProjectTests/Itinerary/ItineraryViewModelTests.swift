import Testing
@testable import ZanzarProject

@Suite("ItineraryViewModel")
struct ItineraryViewModelTests {
    @Test("TODO: describe the expected behavior")
    func example() async throws {
        let viewModel = ItineraryViewModel(service: MockItineraryService())
        // TODO: exercise viewModel and #expect(...) on the result
    }
}

final class MockItineraryService: ItineraryServicing {
    var submitItineraryResult: Result<ItineraryResponse, Error>?

    func submitItinerary(_ request: ItineraryRequest) async throws -> ItineraryResponse {
        guard let result = submitItineraryResult else {
            fatalError("MockItineraryService.submitItineraryResult not configured")
        }
        return try result.get()
    }
}
