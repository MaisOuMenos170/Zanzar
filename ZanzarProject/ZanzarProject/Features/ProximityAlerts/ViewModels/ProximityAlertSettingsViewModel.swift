import Foundation
import Observation

/// The "Alerts nearby" section of the Profile: the two on/off switches, and whether the system permissions that make
/// them work with the app closed are in place.
@Observable
final class ProximityAlertSettingsViewModel {
    nonisolated enum Permissions: Hashable, Sendable {
        /// Not read yet.
        case unknown
        case complete
        /// Something is missing and the system will still ask.
        case canTurnOn
        /// The user said no (or kept "While Using"); only the Settings app can change it.
        case needsSettings(ProximityPermissionViewModel.Missing)
    }

    private(set) var settings: ProximityAlertSettings
    private(set) var permissions: Permissions = .unknown
    private(set) var isWorking = false

    private let service: ProximityPermissionServicing
    private let store: ProximityAlertStoring
    private let onChanged: () async -> Void
    /// Set when the user kept "While Using" at the upgrade dialog: iOS will not show it again.
    private var locationUpgradeDeclined = false

    init(
        service: ProximityPermissionServicing,
        store: ProximityAlertStoring,
        onChanged: @escaping () async -> Void = {}
    ) {
        self.service = service
        self.store = store
        self.onChanged = onChanged
        settings = store.loadSettings()
    }

    /// Reads the switches and the permissions. Call it when the section appears and when the app comes back from
    /// the Settings app.
    func load() async {
        settings = store.loadSettings()
        permissions = Self.permissions(for: await service.status(), locationUpgradeDeclined: locationUpgradeDeclined)
    }

    func setNearbyPlacesEnabled(_ isEnabled: Bool) async {
        settings.nearbyPlacesEnabled = isEnabled
        await persistSettings()
    }

    func setItineraryEnabled(_ isEnabled: Bool) async {
        settings.itineraryEnabled = isEnabled
        await persistSettings()
    }

    /// "Turn on alerts": asks for what is missing.
    func turnOn() async {
        isWorking = true
        defer { isWorking = false }

        let outcome = await ProximityPermissionFlow(service: service).run()
        locationUpgradeDeclined = outcome == .locationNotAlways
        await load()
        await onChanged()
    }

    func openSettings() {
        service.openSettings()
    }

    private func persistSettings() async {
        store.saveSettings(settings)
        await onChanged()
    }

    private static func permissions(
        for status: ProximityPermissionStatus,
        locationUpgradeDeclined: Bool
    ) -> Permissions {
        if status.isComplete { return .complete }
        if status.notifications == .denied { return .needsSettings(.notifications) }
        if status.location == .denied { return .needsSettings(.location) }
        if locationUpgradeDeclined, status.location == .whenInUse { return .needsSettings(.location) }
        return .canTurnOn
    }
}
