import CoreLocation
import Foundation

nonisolated struct PlaceDetail: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let nickname: String?
    let latitude: Double
    let longitude: Double
    let distanceText: String?
    let walkingTimeText: String?
    let openingHoursText: String
    let isOpen: Bool?
    let tags: [PlaceDetailTag]
    let category: ZanzarPlaceCategory
    let description: String
    /// Photos of the place in the order the backend sends them, at most `maximumPhotoCount`.
    let photos: [PlacePhoto]
    var totalCheckIns: Int
    var reactions: [PlaceDetailReaction]
    var hasCheckedIn: Bool
    var isInActiveItinerary: Bool
    var selectedReactionTag: String?

    /// The detail shows only the first few photos; each one is a request when it scrolls into view.
    static let maximumPhotoCount = 5

    var displayName: String {
        PlaceDisplayNameResolver.displayName(nickname: nickname, name: name)
    }
}

nonisolated struct PlaceDetailTag: Identifiable, Hashable, Sendable {
    let id: String
    let label: String
    let style: PlaceDetailTagStyle
}

nonisolated enum PlaceDetailTagStyle: Hashable, Sendable {
    case park
    case touristSpot
    case category
}

nonisolated struct PlaceDetailReaction: Identifiable, Hashable, Sendable {
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

nonisolated struct PlaceDetailNearbyPlace: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let nickname: String?
    let latitude: Double
    let longitude: Double
    let category: ZanzarPlaceCategory
    let distanceMeters: Double
    let checkInCount: Int
    let photoURL: URL?
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

nonisolated extension PlaceDetailNearbyPlace {
    init(mapPlace: MapPlace) {
        self.init(
            id: mapPlace.id,
            name: mapPlace.name,
            nickname: mapPlace.nickname,
            latitude: mapPlace.latitude,
            longitude: mapPlace.longitude,
            category: mapPlace.category,
            distanceMeters: mapPlace.distanceMeters ?? 0,
            checkInCount: mapPlace.checkInCount,
            photoURL: mapPlace.photoURL,
            reactionImageNames: ImpressionTag.topReactionImageNames(from: mapPlace.impressionCounts),
            hasCheckedIn: mapPlace.pinStyle == .checkedIn
        )
    }
}

nonisolated struct PlaceDetailLoadContext: Sendable {
    let place: MapPlace
    let userCoordinate: UserCoordinate?
    let userID: String?
}

nonisolated extension PlaceDetail {
    /// Average walking speed in meters per second (5 km/h ≈ 1.39 m/s)
    private static let walkingSpeedMetersPerSecond: Double = 1.39

    @MainActor static func make(
        placeResponse: PlaceDetailAPIResponse,
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
            L10n.string("placeDetail.header.distanceFormat", $0 / 1000)
        }
        let walkingTimeText = distanceMeters.map { meters in
            let walkingTimeSeconds = meters / walkingSpeedMetersPerSecond
            let minutes = Int(walkingTimeSeconds / 60)
            if minutes < 1 {
                return L10n.string("placeDetail.header.walkingTimeLessThanMinute")
            } else if minutes == 1 {
                return L10n.string("placeDetail.header.walkingTimeOneMinute")
            } else if minutes < 60 {
                return L10n.string("placeDetail.header.walkingTimeMinutes", minutes)
            } else {
                let hours = minutes / 60
                let remainingMinutes = minutes % 60
                if remainingMinutes == 0 {
                    return hours == 1
                        ? L10n.string("placeDetail.header.walkingTimeOneHour")
                        : L10n.string("placeDetail.header.walkingTimeHours", hours)
                } else {
                    return L10n.string("placeDetail.header.walkingTimeHoursMinutes", hours, remainingMinutes)
                }
            }
        }

        let description = placeResponse.editorialSummary?.overview
            ?? placeResponse.formattedAddress
            ?? L10n.string("placeDetail.details.fallbackDescription")

        let openingHours = openingHoursText(from: placeResponse.openingHours)

        return PlaceDetail(
            id: placeResponse.placeId,
            name: placeResponse.name,
            nickname: placeResponse.nickname,
            latitude: placeResponse.geometry.location.lat,
            longitude: placeResponse.geometry.location.lng,
            distanceText: distanceText,
            walkingTimeText: walkingTimeText,
            openingHoursText: openingHours.text,
            isOpen: openingHours.isOpen,
            tags: tags(from: placeResponse),
            category: ZanzarPlaceCategory(rawCategory: placeResponse.zanzar.category),
            description: description,
            photos: Array(placeResponse.photos.prefix(PlaceDetail.maximumPhotoCount)),
            totalCheckIns: placeResponse.zanzar.checkInCount,
            reactions: ImpressionTag.reactions(
                from: placeResponse.zanzar.impressionCounts,
                selectedTag: selectedReactionTag
            ),
            hasCheckedIn: hasCheckedIn,
            isInActiveItinerary: placeResponse.userContext?.isInActiveItinerary ?? false,
            selectedReactionTag: selectedReactionTag
        )
    }

    @MainActor private static func openingHoursText(from openingHours: PlaceDetailOpeningHoursResponse?) -> (text: String, isOpen: Bool?) {
        guard let openingHours else {
            return (L10n.string("placeDetail.header.hoursUnavailable"), nil)
        }
        if openingHours.openNow == true {
            return (L10n.string("placeDetail.header.openNow"), true)
        }
        if openingHours.openNow == false {
            return (L10n.string("placeDetail.header.closedNow"), false)
        }
        return (L10n.string("placeDetail.header.hoursUnavailable"), nil)
    }

    @MainActor private static func tags(from response: PlaceDetailAPIResponse) -> [PlaceDetailTag] {
        var tags: [PlaceDetailTag] = []

        if let categoryTag = categoryTag(for: response.zanzar.category) {
            tags.append(categoryTag)
        }

        for tag in response.zanzar.tags.prefix(2) where !tags.contains(where: { isSameTag($0.label, tag) }) {
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

    /// The API repeats the category as a raw slug ("histórico") next to the localized chip ("Histórico").
    private static func isSameTag(_ lhs: String, _ rhs: String) -> Bool {
        normalizedTag(lhs) == normalizedTag(rhs)
    }

    private static func normalizedTag(_ value: String) -> String {
        value.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }

    @MainActor private static func categoryTag(for category: String) -> PlaceDetailTag? {
        switch ZanzarPlaceCategory(rawCategory: category) {
        case .park:
            categoryTag("park", label: L10n.string("placeDetail.tag.park"), style: .park)
        case .tourist:
            categoryTag("tourist", label: L10n.string("placeDetail.tag.touristSpot"), style: .touristSpot)
        case .restaurant:
            categoryTag("restaurant", label: L10n.string("placeDetail.tag.restaurant"), style: .category)
        case .bar:
            categoryTag("bar", label: L10n.string("placeDetail.tag.bar"), style: .category)
        case .cafe:
            categoryTag("cafe", label: L10n.string("placeDetail.tag.cafe"), style: .category)
        case .museum:
            categoryTag("museum", label: L10n.string("placeDetail.tag.museum"), style: .category)
        case .historic:
            categoryTag("historic", label: L10n.string("placeDetail.tag.historic"), style: .touristSpot)
        case .curiosity:
            categoryTag("curiosity", label: L10n.string("placeDetail.tag.curiosity"), style: .category)
        case .party:
            categoryTag("party", label: L10n.string("placeDetail.tag.party"), style: .category)
        case .unknown:
            nil
        }
    }

    private static func categoryTag(_ slug: String, label: String, style: PlaceDetailTagStyle) -> PlaceDetailTag {
        PlaceDetailTag(id: "category-\(slug)", label: label, style: style)
    }
}
