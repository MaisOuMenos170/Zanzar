import Foundation

/// Remembers the last status seen for each of the user's suggestions and when the app last looked, so a finished
/// review (added, not approved) is told once when the app opens. Only suggestion ids, statuses and one date are
/// kept on the device.
protocol PlaceSuggestionStatusStoring: AnyObject {
    func lastSeenStatuses() -> [String: String]
    func lastCheckedAt() -> Date?
    func save(_ statuses: [String: String], checkedAt: Date)
}

final class UserDefaultsPlaceSuggestionStatusStore: PlaceSuggestionStatusStoring {
    private let defaults: UserDefaults
    private static let statusesKey = "placeSuggestions.lastSeenStatuses"
    private static let checkedAtKey = "placeSuggestions.lastCheckedAt"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func lastSeenStatuses() -> [String: String] {
        defaults.dictionary(forKey: Self.statusesKey) as? [String: String] ?? [:]
    }

    func lastCheckedAt() -> Date? {
        defaults.object(forKey: Self.checkedAtKey) as? Date
    }

    func save(_ statuses: [String: String], checkedAt: Date) {
        defaults.set(statuses, forKey: Self.statusesKey)
        defaults.set(checkedAt, forKey: Self.checkedAtKey)
    }
}
