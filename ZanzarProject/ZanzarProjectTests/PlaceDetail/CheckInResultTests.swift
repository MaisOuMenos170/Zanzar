import Foundation
import Testing
@testable import ZanzarProject

@MainActor
@Suite("CheckInResult")
struct CheckInResultTests {
    private static let responseJSON = """
    {
      "stampIdGranted": "stamp_bar",
      "isNewStamp": true,
      "itineraryProgress": { "completedSlots": 2, "totalSlots": 5 },
      "isItineraryCompleted": false
    }
    """

    @Test("maps the synchronous check-in payload")
    func mapsResponse() throws {
        let result = try Self.decode(Self.responseJSON)

        #expect(result.stampID == "stamp_bar")
        #expect(result.isNewStamp)
        #expect(result.sealCategory == .bar)
        #expect(result.completedItinerarySlots == 2)
        #expect(result.totalItinerarySlots == 5)
        #expect(result.isItineraryCompleted == false)
    }

    @Test("maps a payload without itinerary progress")
    func mapsWithoutItineraryProgress() throws {
        let json = """
        {
          "stampIdGranted": "stamp_park",
          "isNewStamp": false,
          "itineraryProgress": null,
          "isItineraryCompleted": false
        }
        """

        let result = try Self.decode(json)

        #expect(result.isNewStamp == false)
        #expect(result.completedItinerarySlots == nil)
        #expect(result.totalItinerarySlots == nil)
    }

    private static func decode(_ json: String) throws -> CheckInResult {
        try JSONDecoder().decode(CheckInAPIResponse.self, from: Data(json.utf8)).makeCheckInResult()
    }
}
