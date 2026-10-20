import Foundation
import Testing
@testable import ZanzarProject

@Suite("PlaceDetail nearby selection")
struct PlaceDetailNearbySelectionTests {
    private static let mainPlaceJSON = """
    {
      "place_id": "place-main",
      "name": "Museu",
      "geometry": { "location": { "lat": -25.41, "lng": -49.27 } },
      "photos": [],
      "zanzar": { "category": "museum", "tags": [], "checkInCount": 5, "impressionCounts": {} }
    }
    """

    @Test("Nearby places are the closest six, nearest first")
    func nearbyPlacesAreTheClosestSix() throws {
        let mainPlace = try JSONDecoder().decode(PlaceDetailAPIResponse.self, from: Data(Self.mainPlaceJSON.utf8))
        let shared = [900, 100, 700, 300, 500, 800, 200, 600, 400].map { distance in
            MapPlace(
                id: "place-\(distance)",
                name: "Lugar \(distance)",
                latitude: -25.42,
                longitude: -49.31,
                category: .park,
                distanceMeters: Double(distance)
            )
        }

        let detail = PlaceDetail.make(
            placeResponse: mainPlace,
            nearbyPlaces: shared,
            mapPlace: MapPlace(
                id: "place-main",
                name: "Museu",
                latitude: -25.41,
                longitude: -49.27,
                category: .museum,
                distanceMeters: 1200
            ),
            hasCheckedIn: false,
            selectedReactionTag: nil
        )

        #expect(detail.nearbyPlaces.map(\.distanceMeters) == [100, 200, 300, 400, 500, 600])
    }
}
