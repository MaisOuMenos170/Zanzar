import Foundation
import Testing
@testable import ZanzarProject

@Suite("ProfileCheckIn")
struct ProfileCheckInTests {
    private static let checkIn = ProfileCheckIn(
        id: "p1|d1",
        placeID: "ChIJ1",
        placeName: "Parque",
        date: .now,
        photoReference: "AUacSh",
        sealCategory: .park,
        impressionTag: .happy
    )

    @Test("mapPlace preserves place id and checked-in pin style")
    func mapPlace() {
        let place = Self.checkIn.mapPlace

        #expect(place.id == "ChIJ1")
        #expect(place.name == "Parque")
        #expect(place.category == .park)
        #expect(place.pinStyle == .checkedIn)
        #expect(place.distanceMeters == nil)
    }

    @Test("withID replaces only the identifier")
    func withID() {
        let updated = Self.checkIn.withID("custom-id")

        #expect(updated.id == "custom-id")
        #expect(updated.placeID == Self.checkIn.placeID)
        #expect(updated.impressionTag == .happy)
    }
}
