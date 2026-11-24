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

    @Test @MainActor func sentSuggestionToastIsTheDesignMessage() {
        let outcome = PlaceSuggestionOutcome.success

        #expect(outcome.toastMessage == L10n.string("placeSuggestion.toast.success"))
        #expect(outcome.toastMessage != "placeSuggestion.toast.success")
        #expect(outcome.toastStyle == .positive)
    }

    @Test @MainActor func publishedSuggestionToastNamesThePlace() {
        let outcome = PlaceSuggestionOutcome.published(placeName: "Bar do Zé")

        #expect(outcome.toastMessage.contains("Bar do Zé"))
        #expect(outcome.toastStyle == .positive)
    }

    @Test @MainActor func refusedSuggestionToastGivesTheReason() {
        let outcome = PlaceSuggestionOutcome.refused(.duplicate)

        #expect(outcome.toastMessage.contains(L10n.string(PlaceSuggestionDecisionReason.duplicate.messageKey)))
        #expect(outcome.toastStyle == .negative)
    }

    @Test @MainActor func failedSuggestionToastIsTheMessage() {
        let outcome = PlaceSuggestionOutcome.failure(message: "Sem internet")

        #expect(outcome.toastMessage == "Sem internet")
        #expect(outcome.toastStyle == .negative)
    }

    @Test @MainActor func toastMessagesExistInBothLanguages() {
        let keys = ["placeSuggestion.toast.success", "placeSuggestion.toast.published", "placeSuggestion.toast.refused"]
        for key in keys {
            #expect(L10n.string(key) != key)
        }
    }
}
