import Testing
@testable import ZanzarProject

@Suite("PlaceDetail reactions display")
struct PlaceDetailReactionsTests {
    private func reactions(_ counts: [String: Int], selected: String? = nil) -> [PlaceDetailReaction] {
        ImpressionTag.reactions(from: counts, selectedTag: selected)
    }

    @Test("reactions are sorted by most ratings first")
    func sortedByCount() {
        let result = PlaceDetailReaction.displayed(
            reactions(["sad": 1, "happy": 5, "sleepy": 3])
        )

        #expect(result.map(\.impressionTag) == ["happy", "sleepy", "sad"])
    }

    @Test("ties keep the original emotion order")
    func tiesKeepOrder() {
        let result = PlaceDetailReaction.displayed(
            reactions(["sleepy": 2, "delighted": 2, "sad": 2])
        )

        #expect(result.map(\.impressionTag) == ["delighted", "sad", "sleepy"])
    }

    @Test("reactions without ratings are hidden")
    func hidesUnratedWhenReadOnly() {
        let result = PlaceDetailReaction.displayed(reactions(["happy": 2]))

        #expect(result.map(\.impressionTag) == ["happy"])
    }

    @Test("no ratings at all leaves nothing to show")
    func noRatings() {
        #expect(PlaceDetailReaction.displayed(reactions([:])).isEmpty)
    }

    @Test("the user's own reaction is kept even if its count is 0")
    func keepsSelectedReaction() {
        let result = PlaceDetailReaction.displayed(reactions([:], selected: "happy"))

        #expect(result.map(\.impressionTag) == ["happy"])
    }

    @Test("top reaction images list only rated emotions, most rated first")
    func topReactionImages() {
        let names = ImpressionTag.topReactionImageNames(from: ["sad": 1, "nauseated": 4, "delighted": 0])

        #expect(names == [ImpressionTag.nauseated.imageName, ImpressionTag.sad.imageName])
        #expect(ImpressionTag.topReactionImageNames(from: [:]).isEmpty)
    }
}
