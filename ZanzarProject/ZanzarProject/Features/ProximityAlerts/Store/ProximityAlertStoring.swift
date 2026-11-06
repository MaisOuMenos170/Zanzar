import Foundation

/// Where the proximity-alert settings and history live between launches.
nonisolated protocol ProximityAlertStoring: Sendable {
    func loadHistory() -> ProximityAlertHistory
    func saveHistory(_ history: ProximityAlertHistory)
    func loadSettings() -> ProximityAlertSettings
    func saveSettings(_ settings: ProximityAlertSettings)
    /// The places currently watched, with what is needed to build their alert after a background relaunch.
    func loadMonitoredPlaces() -> [ProximityPlaceSnapshot]
    func saveMonitoredPlaces(_ places: [ProximityPlaceSnapshot])
    func loadPromptState() -> ProximityPermissionPromptState
    func savePromptState(_ state: ProximityPermissionPromptState)
}
