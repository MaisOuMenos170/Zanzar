import Foundation

/// Remembers the last status seen for each of the user's photos, so a change (published, not approved,
/// removed) can be told once when the app opens. Only photo ids and statuses are kept on the device.
protocol UserPhotoStatusStoring: AnyObject {
    func lastSeenStatuses() -> [String: String]
    func save(_ statuses: [String: String])
}

final class UserDefaultsUserPhotoStatusStore: UserPhotoStatusStoring {
    private let defaults: UserDefaults
    private static let key = "userPhotos.lastSeenStatuses"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func lastSeenStatuses() -> [String: String] {
        defaults.dictionary(forKey: Self.key) as? [String: String] ?? [:]
    }

    func save(_ statuses: [String: String]) {
        defaults.set(statuses, forKey: Self.key)
    }
}
