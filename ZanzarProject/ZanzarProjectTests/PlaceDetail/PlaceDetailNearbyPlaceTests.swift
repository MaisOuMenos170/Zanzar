import Foundation
import Testing
@testable import ZanzarProject

@Suite("PlaceDetail nearby places")
struct PlaceDetailNearbyPlaceTests {
    @Test("Nearby places map from API responses with navigation metadata")
    func nearbyPlacesMapFromAPIResponses() throws {
        let mainPlace = try makeAPIResponse(
            APIResponseFixture(
                placeId: "place-main",
                name: "Museu",
                lat: -25.41,
                lng: -49.27,
                category: "museum",
                checkInCount: 5,
                distanceMeters: nil
            )
        )
        let nearbyPlace = try makeAPIResponse(
            APIResponseFixture(
                placeId: "place-nearby",
                name: "Parque Barigui",
                lat: -25.42,
                lng: -49.31,
                category: "park",
                checkInCount: 21,
                distanceMeters: 850
            )
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
        #expect(cardPlace.displayName == "Parque Barigui")
        #expect(cardPlace.hasCheckedIn == false)
        #expect(cardPlace.checkInCount == 21)
        #expect(cardPlace.latitude == -25.42)
        #expect(cardPlace.longitude == -49.31)
        #expect(cardPlace.category == .park)
        #expect(cardPlace.distanceMeters == 850)
        // Fixture ratings are happy: 2, delighted: 1 — only rated emotions, most rated first.
        #expect(cardPlace.reactionImageNames == [ImpressionTag.happy.imageName, ImpressionTag.delighted.imageName])
        #expect(cardPlace.mapPlace.id == "place-nearby")
    }

    @Test("Nearby places exclude the place currently being viewed")
    func nearbyPlacesExcludeCurrentPlace() throws {
        let mainPlace = try makeAPIResponse(
            APIResponseFixture(
                placeId: "place-main",
                name: "Museu",
                lat: -25.41,
                lng: -49.27,
                category: "museum",
                checkInCount: 5,
                distanceMeters: nil
            )
        )
        let duplicateNearby = try makeAPIResponse(
            APIResponseFixture(
                placeId: "place-main",
                name: "Museu",
                lat: -25.41,
                lng: -49.27,
                category: "museum",
                checkInCount: 5,
                distanceMeters: 100
            )
        )

        let detail = PlaceDetail.make(
            placeResponse: mainPlace,
            nearbyResponses: [duplicateNearby],
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

        #expect(detail.nearbyPlaces.isEmpty)
    }

    @Test("Main place uses nickname for displayName")
    func mainPlaceUsesNicknameForDisplayName() throws {
        let mainPlace = try makeAPIResponse(
            APIResponseFixture(
                placeId: "place-main",
                name: "Oscar Niemeyer Museum",
                nickname: "MON",
                lat: -25.41,
                lng: -49.27,
                category: "museum",
                checkInCount: 5,
                distanceMeters: nil
            )
        )

        let detail = PlaceDetail.make(
            placeResponse: mainPlace,
            nearbyResponses: [],
            mapPlace: MapPlace(
                id: "place-main",
                name: "Oscar Niemeyer Museum",
                nickname: "MON",
                latitude: -25.41,
                longitude: -49.27,
                category: .museum,
                distanceMeters: 1200
            ),
            hasCheckedIn: false,
            selectedReactionTag: nil
        )

        #expect(detail.displayName == "MON")
        #expect(detail.name == "Oscar Niemeyer Museum")
    }

    @Test("Nearby places prefer nickname and decode userContext check-in state")
    func nearbyPlacesPreferNicknameAndCheckInState() throws {
        let mainPlace = try makeAPIResponse(
            APIResponseFixture(
                placeId: "place-main",
                name: "Museu",
                lat: -25.41,
                lng: -49.27,
                category: "museum",
                checkInCount: 5,
                distanceMeters: nil
            )
        )
        let nearbyPlace = try makeAPIResponse(
            APIResponseFixture(
                placeId: "place-nearby",
                name: "Oscar Niemeyer Museum",
                nickname: "MON",
                lat: -25.42,
                lng: -49.31,
                category: "museum",
                checkInCount: 21,
                distanceMeters: 850,
                hasCheckedIn: true
            )
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

        let cardPlace = detail.nearbyPlaces[0]
        #expect(cardPlace.displayName == "MON")
        #expect(cardPlace.hasCheckedIn == true)
    }

    @Test("Category chip is not repeated as a case-variant slug")
    func categoryChipDropsCaseVariantSlug() throws {
        let categoryLabel = String(localized: "placeDetail.tag.historic")
        let response = try makeAPIResponse(
            APIResponseFixture(
                placeId: "place-historic",
                name: "Cavalo Babão",
                lat: -25.43,
                lng: -49.27,
                category: "historic",
                checkInCount: 1,
                distanceMeters: 100,
                tags: [categoryLabel.lowercased(), "centro"]
            )
        )

        let detail = PlaceDetail.make(
            placeResponse: response,
            nearbyResponses: [],
            mapPlace: MapPlace(
                id: "place-historic",
                name: "Cavalo Babão",
                latitude: -25.43,
                longitude: -49.27,
                category: .historic,
                distanceMeters: 100
            ),
            hasCheckedIn: false,
            selectedReactionTag: nil
        )

        let labels = detail.tags.map(\.label)
        let categoryChipCount = labels.filter {
            $0.compare(categoryLabel, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
        }.count
        #expect(categoryChipCount == 1)
        #expect(labels.contains("centro"))
        #expect(labels.count == 2)
    }

    private struct APIResponseFixture {
        let placeId: String
        let name: String
        var nickname: String?
        let lat: Double
        let lng: Double
        let category: String
        let checkInCount: Int
        let distanceMeters: Double?
        var hasCheckedIn = false
        var tags: [String] = []
    }

    private func makeAPIResponse(_ fixture: APIResponseFixture) throws -> PlaceDetailAPIResponse {
        let nicknameField = fixture.nickname.map { ", \"nickname\": \"\($0)\"" } ?? ""
        let hasCheckedIn = fixture.hasCheckedIn ? "true" : "false"
        let userContextField =
            ", \"userContext\": { \"hasCheckedIn\": \(hasCheckedIn), \"isInActiveItinerary\": false }"
        let tagsField = fixture.tags.map { "\"\($0)\"" }.joined(separator: ", ")
        let distanceField = fixture.distanceMeters.map { ", \"distanceMeters\": \($0)" } ?? ""
        let json = """
        {
          "place_id": "\(fixture.placeId)",
          "name": "\(fixture.name)"\(nicknameField),
          "geometry": {
            "location": { "lat": \(fixture.lat), "lng": \(fixture.lng) }
          },
          "photos": [],
          "zanzar": {
            "category": "\(fixture.category)",
            "tags": [\(tagsField)],
            "checkInCount": \(fixture.checkInCount),
            "impressionCounts": { "delighted": 1, "happy": 2 }
          }
          \(distanceField)\(userContextField)
        }
        """

        return try JSONDecoder().decode(PlaceDetailAPIResponse.self, from: Data(json.utf8))
    }
}
