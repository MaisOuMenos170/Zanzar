import Foundation

struct CheckInResult: Equatable, Sendable {
    let stampID: String
    let isNewStamp: Bool
    let completedItinerarySlots: Int?
    let totalItinerarySlots: Int?
    let isItineraryCompleted: Bool

    var sealCategory: ZanzarPlaceCategory? {
        Self.sealCategory(forStampID: stampID)
    }

    /// The backend names stamps `stamp_<category>` (e.g. `stamp_bar`).
    static func sealCategory(forStampID stampID: String) -> ZanzarPlaceCategory? {
        let name = stampID.hasPrefix("stamp_") ? String(stampID.dropFirst("stamp_".count)) : stampID
        let category = ZanzarPlaceCategory(rawCategory: name)
        return category == .unknown ? nil : category
    }
}

struct CheckInAPIResponse: Decodable, Sendable {
    let stampIdGranted: String
    let isNewStamp: Bool
    let itineraryProgress: ItineraryProgress?
    let isItineraryCompleted: Bool

    struct ItineraryProgress: Decodable, Sendable {
        let completedSlots: Int
        let totalSlots: Int
    }

    func makeCheckInResult() -> CheckInResult {
        CheckInResult(
            stampID: stampIdGranted,
            isNewStamp: isNewStamp,
            completedItinerarySlots: itineraryProgress?.completedSlots,
            totalItinerarySlots: itineraryProgress?.totalSlots,
            isItineraryCompleted: isItineraryCompleted
        )
    }
}
