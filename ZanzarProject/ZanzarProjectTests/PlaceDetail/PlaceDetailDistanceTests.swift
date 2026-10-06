import Foundation
import Testing
@testable import ZanzarProject

@MainActor
@Suite("PlaceDetail distance")
struct PlaceDetailDistanceTests {
    private func makeResponse(distanceMeters: Double?) throws -> PlaceDetailAPIResponse {
        let distance = distanceMeters.map { #""distanceMeters": \#($0),"# } ?? ""
        let json = """
        {
          "place_id": "place-1",
          "name": "Museu",
          \(distance)
          "geometry": { "location": { "lat": -25.41, "lng": -49.27 } },
          "photos": [],
          "zanzar": { "category": "museum", "tags": [], "checkInCount": 1, "impressionCounts": {} }
        }
        """
        return try JSONDecoder().decode(PlaceDetailAPIResponse.self, from: Data(json.utf8))
    }

    private func makeDetail(
        response: PlaceDetailAPIResponse,
        mapPlaceDistance: Double?,
        userCoordinate: UserCoordinate? = nil
    ) -> PlaceDetail {
        PlaceDetail.make(
            placeResponse: response,
            nearbyResponses: [],
            mapPlace: MapPlace(
                id: "place-1",
                name: "Museu",
                latitude: 0,
                longitude: 0,
                category: .museum,
                distanceMeters: mapPlaceDistance
            ),
            hasCheckedIn: true,
            selectedReactionTag: nil,
            userCoordinate: userCoordinate
        )
    }

    @Test("uses the distance of the place the user came from")
    func usesMapPlaceDistance() throws {
        let detail = makeDetail(response: try makeResponse(distanceMeters: nil), mapPlaceDistance: 1300)

        #expect(detail.distanceText != nil)
    }

    @Test("hides the distance when neither the API nor the user position provide one")
    func hidesUnknownDistance() throws {
        let detail = makeDetail(response: try makeResponse(distanceMeters: nil), mapPlaceDistance: nil)

        #expect(detail.distanceText == nil)
    }

    @Test("computes the distance from the user position when the entry point had none")
    func computesDistanceFromUserCoordinate() throws {
        let detail = makeDetail(
            response: try makeResponse(distanceMeters: nil),
            mapPlaceDistance: nil,
            userCoordinate: UserCoordinate(latitude: -25.42, longitude: -49.27)
        )

        #expect(detail.distanceText != nil)
    }
}
