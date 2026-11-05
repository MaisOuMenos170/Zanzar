import Testing
@testable import ZanzarProject

@Suite("ApplePlaceMatcher")
struct ApplePlaceMatcherTests {
    // Bar do Alemão, Largo da Ordem. About 0.0009° of latitude is 100 m.
    private let latitude = -25.4278958
    private let longitude = -49.2726731

    private func candidate(_ name: String, metersNorth: Double = 0) -> ApplePlaceCandidate {
        ApplePlaceCandidate(name: name, latitude: latitude + metersNorth / 111_000, longitude: longitude)
    }

    @Test("search drops the extras Apple does not know", arguments: [
        ("Museu Paranaense | MUPA", "Museu Paranaense"),
        ("Arcádia - Sebo & Café - Vinis, Livros, Dvds, Cds", "Arcádia"),
        ("Bar do Alemão", "Bar do Alemão")
    ])
    func searchQuery(name: String, expected: String) {
        #expect(ApplePlaceMatcher.searchQuery(for: name) == expected)
    }

    @Test("matches a close result with the same distinctive word, ignoring accents")
    func matchesCloseResult() {
        let index = ApplePlaceMatcher.bestMatchIndex(
            names: ["Bar do Alemão"],
            latitude: latitude,
            longitude: longitude,
            category: .bar,
            candidates: [candidate("Largo's Bar", metersNorth: 5), candidate("Bar do Alemao", metersNorth: 16)]
        )

        #expect(index == 1)
    }

    @Test("a shared generic word is not a match")
    func rejectsGenericWordOnly() {
        let index = ApplePlaceMatcher.bestMatchIndex(
            names: ["Bar do Alemão"],
            latitude: latitude,
            longitude: longitude,
            category: .bar,
            candidates: [candidate("Berlin Bar", metersNorth: 10)]
        )

        #expect(index == nil)
    }

    @Test("a same-name result too far away is not a match")
    func rejectsFarResult() {
        let index = ApplePlaceMatcher.bestMatchIndex(
            names: ["Bar do Alemão"],
            latitude: latitude,
            longitude: longitude,
            category: .bar,
            candidates: [candidate("Bar do Alemão", metersNorth: 400)]
        )

        #expect(index == nil)
    }

    @Test("parks accept a farther pin")
    func parksAcceptFartherPin() {
        let index = ApplePlaceMatcher.bestMatchIndex(
            names: ["Parque Barigui"],
            latitude: latitude,
            longitude: longitude,
            category: .park,
            candidates: [candidate("Parque Municipal Barigui", metersNorth: 455)]
        )

        #expect(index == 0)
    }

    @Test("the nickname also counts as a name")
    func nicknameCounts() {
        let index = ApplePlaceMatcher.bestMatchIndex(
            names: ["Museu Oscar Niemeyer", "MON"],
            latitude: latitude,
            longitude: longitude,
            category: .museum,
            candidates: [candidate("MON", metersNorth: 30)]
        )

        #expect(index == 0)
    }

    @Test("picks the closest of several matches")
    func picksClosest() {
        let index = ApplePlaceMatcher.bestMatchIndex(
            names: ["Taisho Sushi"],
            latitude: latitude,
            longitude: longitude,
            category: .restaurant,
            candidates: [candidate("Taisho Sushi", metersNorth: 250), candidate("Taisho", metersNorth: 9)]
        )

        #expect(index == 1)
    }
}
