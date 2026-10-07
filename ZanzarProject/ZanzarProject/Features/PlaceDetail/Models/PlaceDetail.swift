import CoreLocation
import Foundation

struct PlaceDetail: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let nickname: String?
    let latitude: Double
    let longitude: Double
    let distanceText: String?
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

    var displayName: String {
        PlaceDisplayNameResolver.displayName(nickname: nickname, name: name)
    }
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

    /// The reactions to show, most rated first (ties keep their original order). Reactions
    /// nobody picked are hidden, except the user's own.
    static func displayed(_ reactions: [PlaceDetailReaction]) -> [PlaceDetailReaction] {
        reactions
            .enumerated()
            .filter { $0.element.count > 0 || $0.element.isSelected }
            .sorted { lhs, rhs in
                lhs.element.count != rhs.element.count
                    ? lhs.element.count > rhs.element.count
                    : lhs.offset < rhs.offset
            }
            .map(\.element)
    }
}

struct PlaceDetailNearbyPlace: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let nickname: String?
    let latitude: Double
    let longitude: Double
    let category: ZanzarPlaceCategory
    let distanceMeters: Double
    let checkInCount: Int
    let photoReference: String?
    let reactionImageNames: [String]
    let hasCheckedIn: Bool

    var displayName: String {
        PlaceDisplayNameResolver.displayName(nickname: nickname, name: name)
    }

    var mapPlace: MapPlace {
        MapPlace(
            id: id,
            name: name,
            nickname: nickname,
            latitude: latitude,
            longitude: longitude,
            category: category,
            distanceMeters: distanceMeters
        )
    }
}

extension PlaceDetailNearbyPlace {
    init(mapPlace: MapPlace) {
        self.init(
            id: mapPlace.id,
            name: mapPlace.name,
            nickname: mapPlace.nickname,
            latitude: mapPlace.latitude,
            longitude: mapPlace.longitude,
            category: mapPlace.category,
            distanceMeters: mapPlace.distanceMeters ?? 0,
            checkInCount: 0,
            photoReference: nil,
            reactionImageNames: [],
            hasCheckedIn: mapPlace.pinStyle == .checkedIn
        )
    }
}

struct PlaceDetailLoadContext: Sendable {
    let place: MapPlace
    let userCoordinate: UserCoordinate?
    let userID: String?
}

extension PlaceDetail {
    static func make(
        placeResponse: PlaceDetailAPIResponse,
        nearbyResponses: [PlaceDetailAPIResponse],
        mapPlace: MapPlace,
        hasCheckedIn: Bool,
        selectedReactionTag: String?,
        userCoordinate: UserCoordinate? = nil
    ) -> PlaceDetail {
        let location = placeResponse.geometry.location
        let distanceMeters = placeResponse.distanceMeters
            ?? mapPlace.distanceMeters
            ?? userCoordinate.map {
                CLLocation(latitude: $0.latitude, longitude: $0.longitude)
                    .distance(from: CLLocation(latitude: location.lat, longitude: location.lng))
            }
        let distanceText = distanceMeters.map {
            String(
                format: String(localized: "placeDetail.header.distanceFormat"),
                locale: Locale.current,
                $0 / 1000
            )
        }

        let description = placeResponse.editorialSummary?.overview
            ?? placeResponse.formattedAddress
            ?? String(localized: "placeDetail.details.fallbackDescription")

        return PlaceDetail(
            id: placeResponse.placeId,
            name: placeResponse.name,
            nickname: placeResponse.nickname,
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
                        nickname: nearby.nickname,
                        latitude: nearby.geometry.location.lat,
                        longitude: nearby.geometry.location.lng,
                        category: ZanzarPlaceCategory(rawCategory: nearby.zanzar.category),
                        distanceMeters: nearby.distanceMeters ?? 0,
                        checkInCount: nearby.zanzar.checkInCount,
                        photoReference: nearby.photos.first?.photoReference,
                        reactionImageNames: ImpressionTag.topReactionImageNames(from: nearby.zanzar.impressionCounts),
                        hasCheckedIn: nearby.userContext?.hasCheckedIn ?? false
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
