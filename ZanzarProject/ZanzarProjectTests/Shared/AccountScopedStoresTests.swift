import Foundation
import Testing
@testable import ZanzarProject

/// What the app remembers about one account's reviews must be gone when another account signs in.
@Suite("Account-scoped stores")
struct AccountScopedStoresTests {
    private func makeDefaults() -> UserDefaults {
        let name = "AccountScopedStoresTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    @Test("clearing the photo status store forgets the statuses and the last check")
    func clearsPhotoStatuses() {
        let store = UserDefaultsUserPhotoStatusStore(defaults: makeDefaults())
        store.save(["a": "approved"], checkedAt: Date())

        store.clear()

        #expect(store.lastSeenStatuses().isEmpty)
        #expect(store.lastCheckedAt() == nil)
    }

    @Test("clearing the suggestion status store forgets the statuses and the last check")
    func clearsSuggestionStatuses() {
        let store = UserDefaultsPlaceSuggestionStatusStore(defaults: makeDefaults())
        store.save(["s": "added"], checkedAt: Date())

        store.clear()

        #expect(store.lastSeenStatuses().isEmpty)
        #expect(store.lastCheckedAt() == nil)
    }
}
