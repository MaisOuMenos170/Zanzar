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

    @Test("keeps the category chip's key")
    func categoryRoundTrips() {
        let pending = PendingRating(
            userID: "user-1",
            placeID: "ChIJ1",
            placeName: "Jardim Botânico",
            latitude: -25.43,
            longitude: -49.27,
            checkedInAt: .now,
            categoryTitleKey: "placeDetail.tag.park"
        )
        store.save(pending)

        #expect(store.load()?.categoryTitleKey == "placeDetail.tag.park")
    }

    @Test("a record saved before the category was kept still loads, without a chip")
    func oldRecordWithoutCategory() throws {
        let json = """
        {"userID":"user-1","placeID":"ChIJ1","placeName":"Bar","latitude":-25.43,"longitude":-49.27,"checkedInAt":0}
        """

        let pending = try JSONDecoder().decode(PendingRating.self, from: Data(json.utf8))

        #expect(pending.placeName == "Bar")
        #expect(pending.categoryTitleKey == nil)
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
