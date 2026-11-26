import Foundation
import Testing
@testable import ZanzarProject

@MainActor
@Suite("PlacePhotoCreditView")
struct PlacePhotoCreditTests {
    @Test("the spoken credit is one sentence with the author and the licence, with no stray commas or gaps")
    func spokenCredit() throws {
        let credit = PhotoCredit(
            author: "Fer14041978",
            license: "CC BY-SA 3.0",
            sourceURL: try #require(URL(string: "https://commons.wikimedia.org/wiki/File:Parque.jpg"))
        )

        let label = PlacePhotoCreditView.accessibilityLabel(for: credit)

        #expect(label == L10n.string("placeDetail.photoCredit.accessibilityLabel", "Fer14041978", "CC BY-SA 3.0"))
        #expect(label.contains("Fer14041978"))
        #expect(label.contains("CC BY-SA 3.0"))
        #expect(!label.contains("  "))
        #expect(!label.contains(",  "))
    }
}
