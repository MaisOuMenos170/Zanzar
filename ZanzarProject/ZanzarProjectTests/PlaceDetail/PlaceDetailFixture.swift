import Foundation
@testable import ZanzarProject

enum PlaceDetailFixture {
    static let userCoordinate = UserCoordinate(latitude: -25.4298844, longitude: -49.2719424)
    static let nearbyUserCoordinate = UserCoordinate(latitude: -25.4, longitude: -49.2, accuracyMeters: 12)

    static let place = MapPlace(
        id: "place-1",
        name: "Jardim Botânico",
        latitude: -25.4,
        longitude: -49.2,
        category: .park,
        distanceMeters: 1300
    )

    static let checkInResult = CheckInResult(
        stampID: "stamp_park",
        isNewStamp: true,
        completedItinerarySlots: 1,
        totalItinerarySlots: 3,
        isItineraryCompleted: false
    )

    static func detail(
        hasCheckedIn: Bool = false,
        isInActiveItinerary: Bool = false,
        selectedReactionTag: String? = nil
    ) -> PlaceDetail {
        PlaceDetail(
            id: place.id,
            name: place.name,
            nickname: nil,
            latitude: place.latitude,
            longitude: place.longitude,
            distanceText: "1.3 km",
            openingHoursText: "Open now",
            tags: [],
            category: .park,
            description: "Description",
            heroPhotoReference: "photo-ref",
            totalCheckIns: 10,
            reactions: ImpressionTag.reactions(from: [:], selectedTag: selectedReactionTag),
            nearbyPlaces: [],
            hasCheckedIn: hasCheckedIn,
            isInActiveItinerary: isInActiveItinerary,
            selectedReactionTag: selectedReactionTag
        )
    }
}
