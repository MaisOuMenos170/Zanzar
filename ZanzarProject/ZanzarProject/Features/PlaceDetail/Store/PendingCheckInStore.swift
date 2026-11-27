import Foundation

/// Where the check-ins waiting for a network are kept between launches. Holds every account's, so a session that
/// expires never loses them; the queue only ever shows and sends the signed-in user's.
@MainActor
protocol PendingCheckInStoring {
    func load() -> [PendingCheckIn]
    func save(_ items: [PendingCheckIn])
}

@MainActor
final class UserDefaultsPendingCheckInStore: PendingCheckInStoring {
    private static let key = "pendingCheckIns"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> [PendingCheckIn] {
        guard let data = defaults.data(forKey: Self.key) else { return [] }
        do {
            return try JSONDecoder().decode([PendingCheckIn].self, from: data)
        } catch {
            AppLog.placeDetail.error("Failed to decode the pending check-ins; keeping the raw data aside", error: error)
            defaults.set(data, forKey: Self.key + ".unreadable")
            defaults.removeObject(forKey: Self.key)
            return []
        }
    }

    func save(_ items: [PendingCheckIn]) {
        if items.isEmpty {
            defaults.removeObject(forKey: Self.key)
            return
        }
        do {
            defaults.set(try JSONEncoder().encode(items), forKey: Self.key)
        } catch {
            AppLog.placeDetail.error("Failed to encode the pending check-ins", error: error)
        }
    }
}
