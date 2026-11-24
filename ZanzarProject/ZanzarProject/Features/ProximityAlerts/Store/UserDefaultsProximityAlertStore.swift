import Foundation

/// Keeps the settings and history as JSON in `UserDefaults`. Unreadable data falls back to the defaults
/// instead of failing: losing the history only means a few alerts may repeat. `UserDefaults` is documented as
/// thread-safe, hence the `@unchecked Sendable`.
nonisolated final class UserDefaultsProximityAlertStore: ProximityAlertStoring, @unchecked Sendable {
    private let defaults: UserDefaults
    private let historyKey = "proximityAlerts.history"
    private let settingsKey = "proximityAlerts.settings"
    private let placesKey = "proximityAlerts.monitoredPlaces"
    private let promptKey = "proximityAlerts.permissionPrompt"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func loadHistory() -> ProximityAlertHistory {
        load(ProximityAlertHistory.self, forKey: historyKey) ?? ProximityAlertHistory()
    }

    func saveHistory(_ history: ProximityAlertHistory) {
        save(history, forKey: historyKey)
    }

    func loadSettings() -> ProximityAlertSettings {
        load(ProximityAlertSettings.self, forKey: settingsKey) ?? ProximityAlertSettings()
    }

    func saveSettings(_ settings: ProximityAlertSettings) {
        save(settings, forKey: settingsKey)
    }

    func loadMonitoredPlaces() -> [ProximityPlaceSnapshot] {
        load([ProximityPlaceSnapshot].self, forKey: placesKey) ?? []
    }

    func saveMonitoredPlaces(_ places: [ProximityPlaceSnapshot]) {
        save(places, forKey: placesKey)
    }

    func loadPromptState() -> ProximityPermissionPromptState {
        load(ProximityPermissionPromptState.self, forKey: promptKey) ?? ProximityPermissionPromptState()
    }

    func savePromptState(_ state: ProximityPermissionPromptState) {
        save(state, forKey: promptKey)
    }

    private func load<Value: Decodable>(_ type: Value.Type, forKey key: String) -> Value? {
        defaults.data(forKey: key).flatMap { try? JSONDecoder().decode(type, from: $0) }
    }

    private func save(_ value: some Encodable, forKey key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        defaults.set(data, forKey: key)
    }
}
