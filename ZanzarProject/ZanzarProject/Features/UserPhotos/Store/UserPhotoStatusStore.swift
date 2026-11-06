import Foundation

/// Remembers the last status seen for each of the user's photos and when the app last looked, so a finished
/// review (published, not approved, removed) is told once when the app opens. Only photo ids, statuses and one
/// date are kept on the device.
protocol UserPhotoStatusStoring: AnyObject {
    func lastSeenStatuses() -> [String: String]
    func lastCheckedAt() -> Date?
    func save(_ statuses: [String: String], checkedAt: Date)
}

final class UserDefaultsUserPhotoStatusStore: UserPhotoStatusStoring {
    private let defaults: UserDefaults
    private static let statusesKey = "userPhotos.lastSeenStatuses"
    private static let checkedAtKey = "userPhotos.lastCheckedAt"

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
