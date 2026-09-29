import Foundation

struct PlaceDetail: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let latitude: Double
    let longitude: Double
    let distanceText: String
    let openingHoursText: String
    let tags: [PlaceDetailTag]
    let description: String
    let heroPhotoReference: String?
    var totalCheckIns: Int
    var reactions: [PlaceDetailReaction]
    let nearbyPlaces: [PlaceDetailNearbyPlace]
    var hasCheckedIn: Bool
    var selectedReactionTag: String?
}

struct PlaceDetailTag: Identifiable, Hashable, Sendable {
    let id: String
    let label: String
    let style: PlaceDetailTagStyle
}

enum PlaceDetailTagStyle: Hashable, Sendable {
    case park
    case touristSpot
    case category
}

struct PlaceDetailReaction: Identifiable, Hashable, Sendable {
    let id: String
    let impressionTag: String
    let imageName: String
    var count: Int
    var isSelected: Bool
}

struct PlaceDetailNearbyPlace: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let checkInCount: Int
    let photoReference: String?
    let reactionImageNames: [String]
}

struct PlaceDetailLoadContext: Sendable {
    let place: MapPlace
    let userID: String?
}

extension PlaceDetail {
    static func make(
        placeResponse: PlaceDetailAPIResponse,
        nearbyResponses: [PlaceDetailAPIResponse],
        mapPlace: MapPlace,
        hasCheckedIn: Bool,
        selectedReactionTag: String?
    ) -> PlaceDetail {
        let distanceKilometers = mapPlace.distanceMeters / 1000
        let distanceText = String(
            format: String(localized: "placeDetail.header.distanceFormat"),
            locale: Locale.current,
            distanceKilometers
        )

        let description = placeResponse.editorialSummary?.overview
            ?? placeResponse.formattedAddress
            ?? String(localized: "placeDetail.details.fallbackDescription")

        return PlaceDetail(
            id: placeResponse.placeId,
            name: placeResponse.name,
            latitude: placeResponse.geometry.location.lat,
            longitude: placeResponse.geometry.location.lng,
            distanceText: distanceText,
            openingHoursText: openingHoursText(from: placeResponse.openingHours),
            tags: tags(from: placeResponse),
            description: description,
            heroPhotoReference: placeResponse.photos.first?.photoReference,
            totalCheckIns: placeResponse.zanzar.checkInCount,
            reactions: ImpressionTag.reactions(
                from: placeResponse.zanzar.impressionCounts,
                selectedTag: selectedReactionTag
            ),
            nearbyPlaces: nearbyResponses
                .filter { $0.placeId != placeResponse.placeId }
                .prefix(6)
                .map { nearby in
                    PlaceDetailNearbyPlace(
                        id: nearby.placeId,
                        name: nearby.name,
                        checkInCount: nearby.zanzar.checkInCount,
                        photoReference: nearby.photos.first?.photoReference,
                        reactionImageNames: ImpressionTag.topReactionImageNames(
                            from: nearby.zanzar.impressionCounts
                        )
                    )
                },
            hasCheckedIn: hasCheckedIn,
            selectedReactionTag: selectedReactionTag
        )
    }

    private static func openingHoursText(from openingHours: PlaceDetailAPIResponse.OpeningHours?) -> String {
        guard let openingHours else {
            return String(localized: "placeDetail.header.hoursUnavailable")
        }
        if openingHours.openNow == true {
            return String(localized: "placeDetail.header.openNow")
        }
        if openingHours.openNow == false {
            return String(localized: "placeDetail.header.closedNow")
        }
        return String(localized: "placeDetail.header.hoursUnavailable")
    }

    private static func tags(from response: PlaceDetailAPIResponse) -> [PlaceDetailTag] {
        var tags: [PlaceDetailTag] = []

        if let categoryTag = categoryTag(for: response.zanzar.category) {
            tags.append(categoryTag)
        }

        for tag in response.zanzar.tags.prefix(2) where !tags.contains(where: { $0.label == tag }) {
            tags.append(
                PlaceDetailTag(
                    id: "tag-\(tag)",
                    label: tag,
                    style: .category
                )
            )
        }

        return tags
    }

    private static func categoryTag(for category: String) -> PlaceDetailTag? {
        switch ZanzarPlaceCategory(rawCategory: category) {
        case .park:
            PlaceDetailTag(
                id: "category-park",
                label: String(localized: "placeDetail.tag.park"),
                style: .park
            )
        case .tourist, .historic, .museum:
            PlaceDetailTag(
                id: "category-tourist",
                label: String(localized: "placeDetail.tag.touristSpot"),
                style: .touristSpot
            )
        default:
            nil
        }
    }
}
