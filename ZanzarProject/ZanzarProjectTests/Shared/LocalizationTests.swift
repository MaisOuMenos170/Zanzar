import Foundation
import Testing

@testable import ZanzarProject

/// `L10n.string` looks a key up exactly as written. A catalog entry named `key %lld` (the form SwiftUI
/// `Text` interpolation uses) is not found by `L10n.string("key", count)`, and the key itself ends up on screen.
@Suite("Localization")
struct LocalizationTests {
    @Test("the check-ins count on a nearby place card is localized, not the raw key")
    func nearbyPlaceCheckInsCount() {
        let text = L10n.string("placeDetail.nearbyPlace.checkInsCount", 4)

        #expect(text.contains("4"))
        #expect(!text.contains("placeDetail"))
    }

    @Test("the rate limit message is localized, not the raw key")
    func rateLimitedMessage() {
        let text = L10n.string("error.rateLimited.message", 7)

        #expect(text.contains("7"))
        #expect(!text.contains("error.rateLimited"))
    }

    @Test("the itinerary counts that SwiftUI looks up with a %lld key are filled in")
    func itineraryCounts() {
        let bundle = Bundle(for: AppCoordinator.self)

        for key in ["itinerary.card.placesCount %lld", "itinerary.card.completedCount %lld",
                    "itinerary.detail.placesCount %lld", "itinerary.detail.completedCount %lld"] {
            let format = bundle.localizedString(forKey: key, value: nil, table: nil)

            #expect(format != key, "\(key) has no translation")
            #expect(String(format: format, 12).contains("12"), "\(key)")
        }
    }
}
