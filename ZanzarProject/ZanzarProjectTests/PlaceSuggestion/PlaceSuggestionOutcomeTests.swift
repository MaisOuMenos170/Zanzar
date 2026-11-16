import Testing
@testable import ZanzarProject

struct PlaceSuggestionOutcomeTests {
    @Test func sentSuggestionIsGoodNews() {
        #expect(PlaceSuggestionOutcome.success.isGoodNews)
    }

    @Test func publishedSuggestionIsGoodNews() {
        #expect(PlaceSuggestionOutcome.published(placeName: "Bar do Zé").isGoodNews)
    }

    @Test func refusedSuggestionIsNotGoodNews() {
        #expect(!PlaceSuggestionOutcome.refused(.acceptedManual).isGoodNews)
    }

    @Test func failedSuggestionIsNotGoodNews() {
        #expect(!PlaceSuggestionOutcome.failure(message: "offline").isGoodNews)
    }
}
