import Foundation
import Testing

@Suite("RatingPrompt response decoding")
struct RatingPromptResponseDecodingTests {
    private struct RatingResponse: Decodable {
        let impressionTag: String
        let placeId: String
        let impressionCounts: [String: Int]?
    }

    @Test("Rating response decodes without impressionCounts")
    func missingImpressionCounts() throws {
        let json = """
        {
          "impressionTag": "happy",
          "placeId": "place-1"
        }
        """
        let response = try JSONDecoder().decode(RatingResponse.self, from: Data(json.utf8))

        #expect(response.impressionTag == "happy")
        #expect(response.placeId == "place-1")
        #expect(response.impressionCounts == nil)
    }

    @Test("Rating response decodes impressionCounts when present")
    func presentImpressionCounts() throws {
        let json = """
        {
          "impressionTag": "happy",
          "placeId": "place-1",
          "impressionCounts": { "happy": 2, "sad": 1 }
        }
        """
        let response = try JSONDecoder().decode(RatingResponse.self, from: Data(json.utf8))

        #expect(response.impressionCounts?["happy"] == 2)
        #expect(response.impressionCounts?["sad"] == 1)
    }
}
