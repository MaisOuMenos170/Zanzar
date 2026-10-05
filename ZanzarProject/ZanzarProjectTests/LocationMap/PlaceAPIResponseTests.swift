import Foundation
import Testing
@testable import ZanzarProject

@Suite("PlaceAPIResponse")
struct PlaceAPIResponseTests {
    @Test("Decodes backend payload into MapPlace")
    func decodesMapPlace() throws {
        let jsonString = """
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
        """
        let json = Data(jsonString.utf8)

        let response = try JSONDecoder().decode(PlaceAPIResponse.self, from: json)
        let place = MapPlace(response: response)

        #expect(place.id == "ChIJFWlvqB_k3JQR7jsyAF9M8vU")
        #expect(place.name == "Museu Oscar Niemeyer | MON")
        #expect(place.latitude == -25.4098994)
        #expect(place.longitude == -49.2670599)
        #expect(place.category == .museum)
        #expect(place.distanceMeters == 123.4)
        #expect(place.pinIconName == "building.columns.fill")
        #expect(place.pinStyle == .available)
    }

    @Test("User context maps to checked-in pin style")
    func checkedInPinStyle() throws {
        let jsonString = """
        {
          "place_id": "place-checked-in",
          "name": "Parque",
          "geometry": { "location": { "lat": -25.4, "lng": -49.2 } },
          "zanzar": { "category": "park" },
          "distanceMeters": 100,
          "userContext": { "hasCheckedIn": true, "isInActiveItinerary": false }
        }
        """
        let response = try JSONDecoder().decode(PlaceAPIResponse.self, from: Data(jsonString.utf8))
        let place = MapPlace(response: response)

        #expect(place.pinStyle == .checkedIn)
    }

    @Test("User context maps to itinerary pin style")
    func itineraryPinStyle() throws {
        let jsonString = """
        {
          "place_id": "place-itinerary",
          "name": "Museu",
          "geometry": { "location": { "lat": -25.4, "lng": -49.2 } },
          "zanzar": { "category": "museum" },
          "distanceMeters": 100,
          "userContext": { "hasCheckedIn": false, "isInActiveItinerary": true }
        }
        """
        let response = try JSONDecoder().decode(PlaceAPIResponse.self, from: Data(jsonString.utf8))
        let place = MapPlace(response: response)

        #expect(place.pinStyle == .inCurrentItinerary)
    }

    @Test("Checked-in takes priority over itinerary pin style")
    func checkedInOverridesItinerary() throws {
        let jsonString = """
        {
          "place_id": "place-both",
          "name": "Bar",
          "geometry": { "location": { "lat": -25.4, "lng": -49.2 } },
          "zanzar": { "category": "bar" },
          "distanceMeters": 100,
          "userContext": { "hasCheckedIn": true, "isInActiveItinerary": true }
        }
        """
        let response = try JSONDecoder().decode(PlaceAPIResponse.self, from: Data(jsonString.utf8))
        let place = MapPlace(response: response)

        #expect(place.pinStyle == .checkedIn)
    }

    @Test("Explicit null userContext maps to available pin style")
    func nullUserContext() throws {
        let jsonString = """
        {
          "place_id": "place-anonymous",
          "name": "Parque",
          "geometry": { "location": { "lat": -25.4, "lng": -49.2 } },
          "zanzar": { "category": "park" },
          "distanceMeters": 100,
          "userContext": null
        }
        """
        let response = try JSONDecoder().decode(PlaceAPIResponse.self, from: Data(jsonString.utf8))
        let place = MapPlace(response: response)

        #expect(place.pinStyle == .available)
    }

    @Test("Unknown category maps to mappin icon")
    func unknownCategory() throws {
        let jsonString = """
        {
          "place_id": "abc",
          "name": "Mystery Spot",
          "geometry": { "location": { "lat": 0, "lng": 0 } },
          "zanzar": { "category": "unknown_type" },
          "distanceMeters": 0
        }
        """
        let json = Data(jsonString.utf8)

        let response = try JSONDecoder().decode(PlaceAPIResponse.self, from: json)
        let place = MapPlace(response: response)

        #expect(place.category == .unknown)
        #expect(place.pinIconName == "mappin")
    }
}
