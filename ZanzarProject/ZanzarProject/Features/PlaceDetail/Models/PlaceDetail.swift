import Foundation

struct PlaceDetail: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let distanceText: String
    let openingHoursText: String
    let tags: [PlaceDetailTag]
    let description: String
    let totalCheckIns: Int
    let reactions: [PlaceDetailReaction]
    let nearbyPlaces: [PlaceDetailNearbyPlace]
    var hasCheckedIn: Bool
}

struct PlaceDetailTag: Identifiable, Hashable, Sendable {
    let id: String
    let labelKey: String
    let style: PlaceDetailTagStyle
}

enum PlaceDetailTagStyle: Hashable, Sendable {
    case park
    case touristSpot
}

struct PlaceDetailReaction: Identifiable, Hashable, Sendable {
    let id: String
    let imageName: String
    let count: Int
}

struct PlaceDetailNearbyPlace: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let checkInCount: Int
    let reactionImageNames: [String]
}

extension PlaceDetail {
    static func mock(for place: MapPlace) -> PlaceDetail {
        let distanceKilometers = place.distanceMeters / 1000
        let distanceText = String(
            format: String(localized: "placeDetail.header.distanceFormat"),
            locale: Locale.current,
            distanceKilometers
        )

        return PlaceDetail(
            id: place.id,
            name: place.name,
            distanceText: distanceText,
            openingHoursText: "placeDetail.header.openTwentyFourHours",
            tags: [
                PlaceDetailTag(id: "park", labelKey: "placeDetail.tag.park", style: .park),
                PlaceDetailTag(id: "tourist", labelKey: "placeDetail.tag.touristSpot", style: .touristSpot)
            ],
            description: "placeDetail.details.mockDescription",
            totalCheckIns: 140,
            reactions: [
                PlaceDetailReaction(id: "excited", imageName: "CarinhaSorrindo", count: 46),
                PlaceDetailReaction(id: "happy", imageName: "CarinhaFeliz", count: 39),
                PlaceDetailReaction(id: "sick", imageName: "CarinhaVomito", count: 23),
                PlaceDetailReaction(id: "crying", imageName: "CarinhaChoro", count: 10),
                PlaceDetailReaction(id: "sleepy", imageName: "CarinhaBocejando", count: 5)
            ],
            nearbyPlaces: [
                PlaceDetailNearbyPlace(
                    id: "nearby-1",
                    name: "Parque Barigui",
                    checkInCount: 21,
                    reactionImageNames: ["CarinhaSorrindo", "CarinhaFeliz", "CarinhaVomito", "CarinhaChoro", "CarinhaBocejando"]
                ),
                PlaceDetailNearbyPlace(
                    id: "nearby-2",
                    name: "Parque Barigui",
                    checkInCount: 21,
                    reactionImageNames: ["CarinhaSorrindo", "CarinhaFeliz", "CarinhaVomito", "CarinhaChoro", "CarinhaBocejando"]
                ),
                PlaceDetailNearbyPlace(
                    id: "nearby-3",
                    name: "Bar",
                    checkInCount: 24,
                    reactionImageNames: ["CarinhaSorrindo", "CarinhaFeliz", "CarinhaVomito", "CarinhaChoro", "CarinhaBocejando"]
                ),
                PlaceDetailNearbyPlace(
                    id: "nearby-4",
                    name: "Parque Barigui",
                    checkInCount: 21,
                    reactionImageNames: ["CarinhaSorrindo", "CarinhaFeliz", "CarinhaVomito", "CarinhaChoro", "CarinhaBocejando"]
                )
            ],
            hasCheckedIn: false
        )
    }
}
