import Foundation

struct PlaceDetail: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let latitude: Double
    let longitude: Double
    let distanceText: String
    let openingHoursText: String
    let tags: [PlaceDetailTag]
    let category: ZanzarPlaceCategory
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
    let latitude: Double
    let longitude: Double
    let category: ZanzarPlaceCategory
    let distanceMeters: Double
    let checkInCount: Int
    let photoReference: String?
    let reactionImageNames: [String]

    var mapPlace: MapPlace {
        MapPlace(
            id: id,
            name: name,
            latitude: latitude,
            longitude: longitude,
            category: category,
            distanceMeters: distanceMeters
        )
    }
}

struct PlaceDetailLoadContext: Sendable {
    let place: MapPlace
    let userCoordinate: UserCoordinate?
    let userID: String?
}

struct PlaceReactionSubmission: Sendable {
    let impressionTag: String
    let impressionCounts: [String: Int]
}

struct PlaceReactionSnapshot: Sendable {
    let impressionCounts: [String: Int]
    let selectedReactionTag: String?
}

extension PlaceDetail {
    mutating func applyReactionState(counts: [String: Int], selectedTag: String?) {
        reactions = ImpressionTag.reactions(from: counts, selectedTag: selectedTag)
        selectedReactionTag = selectedTag
    }
}

extension PlaceDetail {
    static func make(
        placeResponse: PlaceDetailAPIResponse,
        nearbyResponses: [PlaceDetailAPIResponse],
        mapPlace: MapPlace,
        hasCheckedIn: Bool,
        selectedReactionTag: String?
    ) -> PlaceDetail {
        let distanceMeters = placeResponse.distanceMeters ?? mapPlace.distanceMeters
        let distanceKilometers = distanceMeters / 1000
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
            category: ZanzarPlaceCategory(rawCategory: placeResponse.zanzar.category),
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
                        latitude: nearby.geometry.location.lat,
                        longitude: nearby.geometry.location.lng,
                        category: ZanzarPlaceCategory(rawCategory: nearby.zanzar.category),
                        distanceMeters: nearby.distanceMeters ?? 0,
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
        case .tourist:
            PlaceDetailTag(
                id: "category-tourist",
                label: String(localized: "placeDetail.tag.touristSpot"),
                style: .touristSpot
            )
        case .restaurant:
            PlaceDetailTag(
                id: "category-restaurant",
                label: String(localized: "placeDetail.tag.restaurant"),
                style: .category
            )
        case .bar:
            PlaceDetailTag(
                id: "category-bar",
                label: String(localized: "placeDetail.tag.bar"),
                style: .category
            )
        case .cafe:
            PlaceDetailTag(
                id: "category-cafe",
                label: String(localized: "placeDetail.tag.cafe"),
                style: .category
            )
        case .museum:
            PlaceDetailTag(
                id: "category-museum",
                label: String(localized: "placeDetail.tag.museum"),
                style: .category
            )
        case .historic:
            PlaceDetailTag(
                id: "category-historic",
                label: String(localized: "placeDetail.tag.historic"),
                style: .touristSpot
            )
        case .curiosity:
            PlaceDetailTag(
                id: "category-curiosity",
                label: String(localized: "placeDetail.tag.curiosity"),
                style: .category
            )
        case .party:
            PlaceDetailTag(
                id: "category-party",
                label: String(localized: "placeDetail.tag.party"),
                style: .category
            )
        case .unknown:
            nil
        }
    }
}
