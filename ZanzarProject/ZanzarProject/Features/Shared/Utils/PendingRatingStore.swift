import Foundation

@MainActor
protocol PendingRatingStoring {
    func load() -> PendingRating?
    func save(_ pendingRating: PendingRating)
    func clear()
}

nonisolated final class UserDefaultsPendingRatingStore: PendingRatingStoring {
    private static let key = "pendingRating"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> PendingRating? {
        guard let data = defaults.data(forKey: Self.key) else { return nil }
        do {
            return try JSONDecoder().decode(PendingRating.self, from: data)
        } catch {
            AppLog.ratingPrompt.error("Failed to decode stored pending rating; discarding", error: error)
            defaults.removeObject(forKey: Self.key)
            return nil
        }
    }

    func save(_ pendingRating: PendingRating) {
        do {
            defaults.set(try JSONEncoder().encode(pendingRating), forKey: Self.key)
            AppLog.ratingPrompt.info("Saved pending rating placeId=\(pendingRating.placeID)")
        } catch {
            AppLog.ratingPrompt.error("Failed to encode pending rating placeId=\(pendingRating.placeID)", error: error)
        }
    }

    func clear() {
        defaults.removeObject(forKey: Self.key)
    }
}
