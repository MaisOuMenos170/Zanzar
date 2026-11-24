import Foundation
import os
@testable import ZanzarProject

/// A `ProximityAlertStoring` that keeps everything in memory, so tests never touch `UserDefaults`.
nonisolated final class InMemoryProximityAlertStore: ProximityAlertStoring, Sendable {
    private struct State {
        var history = ProximityAlertHistory()
        var settings = ProximityAlertSettings()
        var places: [ProximityPlaceSnapshot] = []
        var prompt = ProximityPermissionPromptState()
    }

    private let state = OSAllocatedUnfairLock(initialState: State())

    func loadHistory() -> ProximityAlertHistory {
        state.withLock { $0.history }
    }

    func saveHistory(_ history: ProximityAlertHistory) {
        state.withLock { $0.history = history }
    }

    func loadSettings() -> ProximityAlertSettings {
        state.withLock { $0.settings }
    }

    func saveSettings(_ settings: ProximityAlertSettings) {
        state.withLock { $0.settings = settings }
    }

    func loadMonitoredPlaces() -> [ProximityPlaceSnapshot] {
        state.withLock { $0.places }
    }

    func saveMonitoredPlaces(_ places: [ProximityPlaceSnapshot]) {
        state.withLock { $0.places = places }
    }

    func loadPromptState() -> ProximityPermissionPromptState {
        state.withLock { $0.prompt }
    }

    func savePromptState(_ prompt: ProximityPermissionPromptState) {
        state.withLock { $0.prompt = prompt }
    }
}
