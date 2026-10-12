import Foundation
import Testing
@testable import ZanzarProject

@MainActor
@Suite("PendingRatingStore", .serialized)
struct PendingRatingStoreTests {
    private let defaults: UserDefaults
    private let store: UserDefaultsPendingRatingStore

    init() {
        defaults = UserDefaults(suiteName: "PendingRatingStoreTests")!
        defaults.removePersistentDomain(forName: "PendingRatingStoreTests")
        store = UserDefaultsPendingRatingStore(defaults: defaults)
    }

    @Test("round-trips a pending rating")
    func saveAndLoad() {
        let pending = PendingRating(
            userID: "user-1",
            placeID: "ChIJ1",
            placeName: "Bar",
            latitude: -25.43,
            longitude: -49.27,
            checkedInAt: .now
        )
        store.save(pending)

        #expect(store.load() == pending)
    }

    @Test("clear removes stored rating")
    func clear() {
        store.save(
            PendingRating(
                userID: "user-1",
                placeID: "ChIJ1",
                placeName: "Bar",
                latitude: -25.43,
                longitude: -49.27,
                checkedInAt: .now
            )
        )
        store.clear()

        #expect(store.load() == nil)
    }
}
