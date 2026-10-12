import Foundation
import Testing
@testable import ZanzarProject

@Suite("ImpressionTag")
struct ImpressionTagTests {
    @Test("ranks reactions by count and declaration order")
    func topReactionImageNames() {
        let names = ImpressionTag.topReactionImageNames(
            from: ["happy": 3, "sad": 3, "sleepy": 1],
            limit: 3
        )

        #expect(names.count == 3)
        #expect(names[0] == ImpressionTag.happy.imageName)
        #expect(names[1] == ImpressionTag.sad.imageName)
        #expect(names[2] == ImpressionTag.sleepy.imageName)
    }

    @Test("builds reactions with selected tag")
    func reactionsFromCounts() {
        let reactions = ImpressionTag.reactions(from: ["happy": 2], selectedTag: "happy")

        #expect(reactions.count == ImpressionTag.allCases.count)
        #expect(reactions.first(where: { $0.impressionTag == "happy" })?.isSelected == true)
        #expect(reactions.first(where: { $0.impressionTag == "happy" })?.count == 2)
    }
}
