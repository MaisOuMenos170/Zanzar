import Foundation
@testable import ZanzarProject

extension PlaceSuggestionViewModelTests {
    nonisolated static func suggestion(
        status: PlaceSuggestionStatus,
        name: String? = nil,
        reason: PlaceSuggestionDecisionReason? = nil
    ) -> MySuggestion {
        MySuggestion(
            id: "s1",
            status: status,
            name: name,
            address: "Rua A",
            note: nil,
            decisionReason: reason,
            placeID: nil,
            createdAt: Date(timeIntervalSince1970: 1_000),
            decidedAt: nil
        )
    }
}

final class MockPlaceSuggestionService: PlaceSuggestionServicing, @unchecked Sendable {
    struct Search: Equatable {
        let query: String
        let near: SuggestedLocation?
    }

    var currentLocationResult: Result<SuggestedLocation, Error> = .success(
        SuggestedLocation(latitude: -25.43, longitude: -49.27, address: "Rua XV de Novembro, 1200")
    )
    var submitResult: Result<PlaceSuggestionOutcome, Error> = .success(.success)
    var searchResult: Result<[SuggestedPlace], Error> = .success([])
    var resolveResult: Result<SuggestedPlace?, Error> = .success(nil)
    var fetchMineResult: Result<[MySuggestion], Error> = .success([])

    private(set) var currentLocationCalls = 0
    private(set) var submitted: [PlaceSuggestion] = []
    private(set) var searches: [Search] = []
    private(set) var resolvedAddresses: [Search] = []
    private(set) var fetchMineCalls = 0

    func currentLocation() async throws -> SuggestedLocation {
        currentLocationCalls += 1
        return try currentLocationResult.get()
    }

    func submit(_ suggestion: PlaceSuggestion) async throws -> PlaceSuggestionOutcome {
        let outcome = try submitResult.get()
        submitted.append(suggestion)
        return outcome
    }

    func searchPlaces(query: String, near: SuggestedLocation?) async throws -> [SuggestedPlace] {
        searches.append(Search(query: query, near: near))
        return try searchResult.get()
    }

    func resolveAddress(_ text: String, near: SuggestedLocation?) async throws -> SuggestedPlace? {
        resolvedAddresses.append(Search(query: text, near: near))
        return try resolveResult.get()
    }

    func fetchMine() async throws -> [MySuggestion] {
        fetchMineCalls += 1
        return try fetchMineResult.get()
    }
}
