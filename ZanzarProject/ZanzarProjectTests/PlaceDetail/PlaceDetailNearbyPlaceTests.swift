import Foundation
import Testing
@testable import ZanzarProject

@Suite("PlaceDetail nearby places")
struct PlaceDetailNearbyPlaceTests {
    @Test("Nearby places map from API responses with navigation metadata")
    func nearbyPlacesMapFromAPIResponses() {
        let mainPlace = makeAPIResponse(
            placeId: "place-main",
            name: "Museu",
            lat: -25.41,
            lng: -49.27,
            category: "museum",
            checkInCount: 5,
            distanceMeters: nil
        )
        let nearbyPlace = makeAPIResponse(
            placeId: "place-nearby",
            name: "Parque Barigui",
            lat: -25.42,
            lng: -49.31,
            category: "park",
            checkInCount: 21,
            distanceMeters: 850
        )

        let detail = PlaceDetail.make(
            placeResponse: mainPlace,
            nearbyResponses: [nearbyPlace],
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

        #expect(detail.nearbyPlaces.count == 1)

        let cardPlace = detail.nearbyPlaces[0]
        #expect(cardPlace.name == "Parque Barigui")
        #expect(cardPlace.checkInCount == 21)
        #expect(cardPlace.latitude == -25.42)
        #expect(cardPlace.longitude == -49.31)
        #expect(cardPlace.category == .park)
        #expect(cardPlace.distanceMeters == 850)
        #expect(cardPlace.reactionImageNames == ImpressionTag.allReactionImageNames)
        #expect(cardPlace.mapPlace.id == "place-nearby")
    }

    private func makeAPIResponse(
        placeId: String,
        name: String,
        lat: Double,
        lng: Double,
        category: String,
        checkInCount: Int,
        distanceMeters: Double?
    ) -> PlaceDetailAPIResponse {
        let json = """
        {
          "place_id": "\(placeId)",
          "name": "\(name)",
          "geometry": {
            "location": { "lat": \(lat), "lng": \(lng) }
          },
          "photos": [],
          "zanzar": {
            "category": "\(category)",
            "tags": [],
            "checkInCount": \(checkInCount),
            "impressionCounts": { "delighted": 1, "happy": 2 }
          }
          \(distanceMeters.map { ", \"distanceMeters\": \($0)" } ?? "")
        }
        """

        return try! JSONDecoder().decode(PlaceDetailAPIResponse.self, from: Data(json.utf8))
    }
}
