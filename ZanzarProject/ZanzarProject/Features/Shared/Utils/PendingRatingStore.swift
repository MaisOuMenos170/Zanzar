import Foundation

@MainActor
protocol PendingRatingStoring {
    func load() -> PendingRating?
    func save(_ pendingRating: PendingRating)
    func clear()
}

final class UserDefaultsPendingRatingStore: PendingRatingStoring {
    private static let key = "pendingRating"
    private let defaults: UserDefaults

    nonisolated init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> PendingRating? {
        guard let data = defaults.data(forKey: Self.key) else { return nil }
        return try? JSONDecoder().decode(PendingRating.self, from: data)
    }

    func save(_ pendingRating: PendingRating) {
        guard let data = try? JSONEncoder().encode(pendingRating) else { return }
        defaults.set(data, forKey: Self.key)
    }

    func clear() {
        defaults.removeObject(forKey: Self.key)
    }
}
