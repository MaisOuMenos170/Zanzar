import Foundation
import Testing
@testable import ZanzarProject

@Suite("PlaceAPIResponse")
struct PlaceAPIResponseTests {
    @Test("Decodes backend payload into MapPlace")
    func decodesMapPlace() throws {
        let json = """
        {
          "place_id": "ChIJFWlvqB_k3JQR7jsyAF9M8vU",
          "name": "Museu Oscar Niemeyer | MON",
          "geometry": {
            "location": {
              "lat": -25.4098994,
              "lng": -49.2670599
            }
          },
          "zanzar": {
            "category": "museum"
          },
          "distanceMeters": 123.4
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(PlaceAPIResponse.self, from: json)
        let place = MapPlace(response: response)

        #expect(place.id == "ChIJFWlvqB_k3JQR7jsyAF9M8vU")
        #expect(place.name == "Museu Oscar Niemeyer | MON")
        #expect(place.latitude == -25.4098994)
        #expect(place.longitude == -49.2670599)
        #expect(place.category == .museum)
        #expect(place.distanceMeters == 123.4)
        #expect(place.pinIconName == "leaf")
    }

    @Test("Unknown category maps to mappin icon")
    func unknownCategory() throws {
        let json = """
        {
          "place_id": "abc",
          "name": "Mystery Spot",
          "geometry": { "location": { "lat": 0, "lng": 0 } },
          "zanzar": { "category": "unknown_type" },
          "distanceMeters": 0
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(PlaceAPIResponse.self, from: json)
        let place = MapPlace(response: response)

        #expect(place.category == .unknown)
        #expect(place.pinIconName == "mappin")
    }
}
