import Foundation
import Testing
@testable import ZanzarProject

@MainActor
@Suite("Itinerary list and detail extra fields")
struct ItineraryServiceExtraFieldsTests {
    private static let plainListJSON = """
    [{
      "slug": "centro-historico", "name": "Centro Histórico", "category": "historic",
      "routeType": "fixed", "placesCount": 2, "completedCount": 42
    }]
    """

    private static let plainDetailJSON = """
    {
      "slug": "centro-historico", "name": "Centro Histórico", "description": "", "category": "historic",
      "routeType": "fixed", "objectives": [], "placesCount": 1, "completedCount": 42, "places": []
    }
    """

    @Test("maps the themes of a list item and skips the ones it does not know")
    func mapsThemes() throws {
        let json = """
        [{
          "slug": "centro-historico", "name": "Centro Histórico", "category": "historic",
          "routeType": "fixed", "placesCount": 2, "completedCount": 1,
          "themes": ["center", "walking", "something-new"]
        }]
        """

        let items = try Self.decodeList(json)

        #expect(items[0].themes == [.center, .walking])
    }

    @Test("a list item without themes has none")
    func listWithoutThemes() throws {
        let items = try Self.decodeList(Self.plainListJSON)

        #expect(items[0].themes.isEmpty)
    }

    @Test("maps the avatars of the people who completed a roteiro")
    func mapsRecentCompleters() throws {
        let json = """
        {
          "slug": "centro-historico", "name": "Centro Histórico", "description": "", "category": "historic",
          "routeType": "fixed", "objectives": [], "placesCount": 1, "completedCount": 42, "places": [],
          "recentCompleters": [
            { "skin": 2, "eyes": 3, "eyebrow": 1, "eyelash": 0, "hair": 4, "background": "#FFE0A2" },
            { "skin": 1, "eyes": 1, "eyebrow": 2, "hair": 0, "background": "#B7BEFE" }
          ]
        }
        """

        let detail = try Self.decodeDetail(json)

        #expect(detail.recentCompleters.count == 2)
        #expect(detail.recentCompleters[0] == Avatar(
            skin: 2, eyes: 3, eyebrow: 1, eyelash: Avatar.none, hair: 4, background: "#FFE0A2"
        ))
        #expect(detail.recentCompleters[1].eyelash == 1)
    }

    @Test("a detail without recentCompleters has none")
    func detailWithoutCompleters() throws {
        let detail = try Self.decodeDetail(Self.plainDetailJSON)

        #expect(detail.recentCompleters.isEmpty)
    }

    private static func decodeDetail(_ json: String) throws -> ItineraryDetail {
        try JSONDecoder().decode(ItineraryDetailAPIResponse.self, from: Data(json.utf8)).makeItineraryDetail()
    }

    private static func decodeList(_ json: String) throws -> [Itinerary] {
        try JSONDecoder().decode([ItineraryListItemAPIResponse].self, from: Data(json.utf8)).map { $0.makeItinerary() }
    }
}
