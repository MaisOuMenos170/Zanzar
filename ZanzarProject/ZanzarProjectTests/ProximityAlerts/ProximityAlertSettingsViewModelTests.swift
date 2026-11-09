import Foundation
import Testing
@testable import ZanzarProject

@Suite("ProximityAlertSettingsViewModel")
struct ProximityAlertSettingsViewModelTests {
    private let store = InMemoryProximityAlertStore()

    private func makeViewModel(
        _ service: FakeProximityPermissionService,
        onChanged: @escaping () async -> Void = {}
    ) -> ProximityAlertSettingsViewModel {
        ProximityAlertSettingsViewModel(service: service, store: store, onChanged: onChanged)
    }

    // MARK: Loading

    @Test("Starts with the saved switches")
    func loadsSettings() async {
        store.saveSettings(ProximityAlertSettings(nearbyPlacesEnabled: false, itineraryEnabled: true))
        let viewModel = makeViewModel(FakeProximityPermissionService())

        await viewModel.load()

        #expect(viewModel.settings.nearbyPlacesEnabled == false)
        #expect(viewModel.settings.itineraryEnabled)
    }

    @Test("Reads the permissions: complete, can still be turned on, or blocked")
    func permissions() async {
        let complete = makeViewModel(FakeProximityPermissionService(notifications: .allowed, location: .always))
        let missing = makeViewModel(FakeProximityPermissionService(notifications: .notDetermined, location: .whenInUse))
        let noNotifications = makeViewModel(FakeProximityPermissionService(notifications: .denied, location: .always))
        let noLocation = makeViewModel(FakeProximityPermissionService(notifications: .allowed, location: .denied))

        for viewModel in [complete, missing, noNotifications, noLocation] {
            await viewModel.load()
        }

        #expect(complete.permissions == .complete)
        #expect(missing.permissions == .canTurnOn)
        #expect(noNotifications.permissions == .needsSettings(.notifications))
        #expect(noLocation.permissions == .needsSettings(.location))
    }

    @Test("Not read until it loads")
    func unknownBeforeLoad() {
        #expect(makeViewModel(FakeProximityPermissionService()).permissions == .unknown)
    }

    // MARK: Switches

    @Test("A switch is saved and the monitored places are re-chosen")
    func togglesSave() async {
        var changedCount = 0
        let viewModel = makeViewModel(FakeProximityPermissionService()) { changedCount += 1 }

        await viewModel.setNearbyPlacesEnabled(false)
        await viewModel.setItineraryEnabled(false)

        #expect(store.loadSettings() == ProximityAlertSettings(nearbyPlacesEnabled: false, itineraryEnabled: false))
        #expect(viewModel.settings == store.loadSettings())
        #expect(changedCount == 2)
    }

    // MARK: Turning on

    @Test("Turn on asks for what is missing and ends complete")
    func turnOn() async {
        let service = FakeProximityPermissionService()
        var changedCount = 0
        let viewModel = makeViewModel(service) { changedCount += 1 }

        await viewModel.turnOn()

        #expect(service.notificationRequests == 1)
        #expect(service.locationRequests == 1)
        #expect(viewModel.permissions == .complete)
        #expect(changedCount == 1)
        #expect(!viewModel.isWorking)
    }

    @Test("Keeping 'While Using' sends the user to Settings, and stays that way when the section reloads")
    func keptWhileUsing() async {
        let service = FakeProximityPermissionService(notifications: .allowed)
        service.locationAnswer = .whenInUse
        let viewModel = makeViewModel(service)

        await viewModel.turnOn()
        await viewModel.load()

        #expect(viewModel.permissions == .needsSettings(.location))
    }

    @Test("Refusing notifications sends the user to Settings")
    func notificationsRefused() async {
        let service = FakeProximityPermissionService()
        service.notificationAnswer = .denied
        let viewModel = makeViewModel(service)

        await viewModel.turnOn()

        #expect(viewModel.permissions == .needsSettings(.notifications))
        #expect(service.locationRequests == 0)
    }

    @Test("Granting 'Always' in Settings afterwards makes it complete")
    func fixedInSettings() async {
        let service = FakeProximityPermissionService(notifications: .allowed)
        service.locationAnswer = .whenInUse
        let viewModel = makeViewModel(service)
        await viewModel.turnOn()

        service.current.location = .always
        await viewModel.load()

        #expect(viewModel.permissions == .complete)
    }

    @Test("Open Settings goes to the Settings app")
    func openSettings() {
        let service = FakeProximityPermissionService()
        makeViewModel(service).openSettings()

        #expect(service.openedSettings == 1)
    }
}
