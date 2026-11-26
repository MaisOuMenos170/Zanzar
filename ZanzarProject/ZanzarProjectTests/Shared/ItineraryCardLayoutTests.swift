import SwiftUI
import Testing

@testable import ZanzarProject

/// The card keeps its 149pt design height at the default text size and grows, instead of cutting the text, when
/// the user asks for larger text.
@MainActor
@Suite("ItineraryCard layout")
struct ItineraryCardLayoutTests {
    private func renderedHeight(name: String, dynamicTypeSize: DynamicTypeSize) -> CGFloat? {
        let card = ItineraryCard(
            itinerary: Itinerary(
                slug: "teste",
                name: name,
                category: "historic",
                routeType: .fixed,
                placesCount: 4,
                completedCount: 20,
                coverImageURL: nil
            ),
            onViewDetails: {}
        )
        .frame(width: 360)
        .environment(\.dynamicTypeSize, dynamicTypeSize)
        let renderer = ImageRenderer(content: card)
        renderer.scale = 1
        return renderer.uiImage?.size.height
    }

    @Test("At the default text size the card is 149 high")
    func defaultHeight() throws {
        let height = try #require(renderedHeight(name: "Bora passear no centro?", dynamicTypeSize: .large))

        #expect(abs(height - 149) < 0.5)
    }

    @Test("At an accessibility text size the card grows with the text")
    func growsWithText() throws {
        let standard = try #require(renderedHeight(name: "Bora passear no centro?", dynamicTypeSize: .large))
        let accessible = try #require(renderedHeight(name: "Bora passear no centro?", dynamicTypeSize: .accessibility5))

        #expect(accessible > standard * 1.3)
    }
}
