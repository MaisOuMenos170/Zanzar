import SwiftUI
import Testing

@testable import ZanzarProject

/// The card has a fixed size, as in the design: 117 wide, 114 of photo and a 72 text block, whatever the
/// name, the check-in count or the reactions are.
@MainActor
@Suite("NearbyPlaceCard layout")
struct NearbyPlaceCardLayoutTests {
    private func renderedSize(of place: MapPlace, dynamicTypeSize: DynamicTypeSize = .large) -> CGSize? {
        let card = NearbyPlaceCard(
            place: PlaceDetailNearbyPlace(mapPlace: place),
            mediaPolicy: PlaceMediaAccessPolicy.shared,
            onTap: {}
        )
        .environment(\.dynamicTypeSize, dynamicTypeSize)
        let renderer = ImageRenderer(content: card)
        renderer.scale = 1
        return renderer.uiImage?.size
    }

    private func place(
        name: String,
        checkInCount: Int,
        impressionCounts: [String: Int]
    ) -> MapPlace {
        MapPlace(
            id: name,
            name: name,
            latitude: -25.43,
            longitude: -49.27,
            category: .park,
            distanceMeters: 100,
            checkInCount: checkInCount,
            impressionCounts: impressionCounts
        )
    }

    @Test("Cards are the same size with a short name and no reactions or a long name and many")
    func sizeDoesNotDependOnContent() throws {
        let plain = try #require(renderedSize(of: place(name: "Bar", checkInCount: 0, impressionCounts: [:])))
        let busy = try #require(renderedSize(of: place(
            name: "Ruínas de São Francisco da Penitência e Convento Antigo",
            checkInCount: 123_456,
            impressionCounts: ["delighted": 5, "happy": 4, "neutral": 3, "sad": 2, "angry": 1]
        )))

        #expect(abs(plain.width - busy.width) < 0.5)
        #expect(abs(plain.height - busy.height) < 0.5)
        #expect(abs(plain.width - 117) < 0.5)
        #expect(abs(plain.height - (114 + 72)) < 0.5)
    }

    @Test("At an accessibility text size the card grows with the text and stays one size for every content")
    func scalesWithAccessibilityTextSize() throws {
        let standard = try #require(renderedSize(of: place(name: "Bar", checkInCount: 0, impressionCounts: [:])))
        let plain = try #require(renderedSize(
            of: place(name: "Bar", checkInCount: 0, impressionCounts: [:]),
            dynamicTypeSize: .accessibility5
        ))
        let busy = try #require(renderedSize(
            of: place(
                name: "Ruínas de São Francisco da Penitência e Convento Antigo",
                checkInCount: 123_456,
                impressionCounts: ["delighted": 5, "happy": 4, "neutral": 3, "sad": 2, "angry": 1]
            ),
            dynamicTypeSize: .accessibility5
        ))

        #expect(plain.width > standard.width * 1.3)
        #expect(plain.height > standard.height * 1.3)
        #expect(abs(plain.width - busy.width) < 0.5)
        #expect(abs(plain.height - busy.height) < 0.5)
    }
}
