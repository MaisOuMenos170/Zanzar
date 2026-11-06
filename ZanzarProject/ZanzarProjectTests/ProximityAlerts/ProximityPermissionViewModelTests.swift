import Foundation
import Testing
@testable import ZanzarProject

@Suite("ProximityPermissionViewModel")
struct ProximityPermissionViewModelTests {
    private let store = InMemoryProximityAlertStore()
    private let clock = TestClock(Date(timeIntervalSince1970: 1_800_000_000))

    private func makeViewModel(
        _ service: FakeProximityPermissionService,
        onChanged: @escaping () async -> Void = {}
    ) -> ProximityPermissionViewModel {
        let clock = clock
        return ProximityPermissionViewModel(
            service: service,
            store: store,
            now: { clock.date },
            onPermissionsChanged: onChanged
        )
    }

    // MARK: When it appears

    @Test("Shows when something can still be granted, and counts the showing")
    func showsWhenMissing() async {
        let viewModel = makeViewModel(FakeProximityPermissionService())

        await viewModel.momentOccurred(.firstCheckIn)

        #expect(viewModel.isVisible)
        #expect(viewModel.step == .intro)
        #expect(store.loadPromptState().timesShown == 1)
        #expect(store.loadPromptState().lastShownAt == clock.date)
    }

    @Test("Stays away when everything is already granted")
    func hiddenWhenComplete() async {
        let service = FakeProximityPermissionService(notifications: .allowed, location: .always)
        let viewModel = makeViewModel(service)

        await viewModel.momentOccurred(.itineraryStarted)

        #expect(!viewModel.isVisible)
        #expect(store.loadPromptState().timesShown == 0)
    }

    @Test("Stays away when the user refused a permission at the system level")
    func hiddenWhenBlocked() async {
        let viewModel = makeViewModel(FakeProximityPermissionService(notifications: .denied))
        let locationBlocked = makeViewModel(FakeProximityPermissionService(location: .denied))

        await viewModel.momentOccurred(.firstCheckIn)
        await locationBlocked.momentOccurred(.firstCheckIn)

        #expect(!viewModel.isVisible)
        #expect(!locationBlocked.isVisible)
    }

    @Test("After 'Not now' it does not come back the next day")
    func respectsSpacing() async {
        let viewModel = makeViewModel(FakeProximityPermissionService())
        await viewModel.momentOccurred(.firstCheckIn)
        viewModel.dismiss()

        clock.advance(by: 24 * 3_600)
        await viewModel.momentOccurred(.itineraryStarted)

        #expect(!viewModel.isVisible)
        #expect(store.loadPromptState().timesShown == 1)
    }

    @Test("It comes back after the spacing has passed")
    func comesBack() async {
        let viewModel = makeViewModel(FakeProximityPermissionService())
        await viewModel.momentOccurred(.firstCheckIn)
        viewModel.dismiss()

        clock.advance(by: 15 * 24 * 3_600)
        await viewModel.momentOccurred(.itineraryStarted)

        #expect(viewModel.isVisible)
        #expect(store.loadPromptState().timesShown == 2)
    }

    // MARK: Turning on

    @Test("Turn on asks for notifications, then 'Always', and ends enabled")
    func enableHappyPath() async {
        let service = FakeProximityPermissionService()
        var changedCount = 0
        let viewModel = makeViewModel(service) { changedCount += 1 }
        await viewModel.momentOccurred(.firstCheckIn)

        await viewModel.enable()

        #expect(service.notificationRequests == 1)
        #expect(service.locationRequests == 1)
        #expect(viewModel.step == .enabled)
        #expect(changedCount == 1)
    }

    @Test("Notifications already allowed are not asked again")
    func skipsNotificationDialog() async {
        let service = FakeProximityPermissionService(notifications: .allowed)
        let viewModel = makeViewModel(service)

        await viewModel.enable()

        #expect(service.notificationRequests == 0)
        #expect(service.locationRequests == 1)
    }

    @Test("Refusing notifications stops there and points to Settings, without asking for location")
    func notificationsRefused() async {
        let service = FakeProximityPermissionService()
        service.notificationAnswer = .denied
        let viewModel = makeViewModel(service)

        await viewModel.enable()

        #expect(viewModel.step == .needsSettings(.notifications))
        #expect(service.locationRequests == 0)
    }

    @Test("Keeping 'While Using' leaves the user one step from done, pointing to Settings")
    func keptWhileUsing() async {
        let service = FakeProximityPermissionService(notifications: .allowed)
        service.locationAnswer = .whenInUse
        var changedCount = 0
        let viewModel = makeViewModel(service) { changedCount += 1 }

        await viewModel.enable()

        #expect(viewModel.step == .needsSettings(.location))
        #expect(changedCount == 1)
    }

    @Test("Open Settings goes to the system settings and closes the card")
    func openSettings() async {
        let service = FakeProximityPermissionService()
        let viewModel = makeViewModel(service)
        await viewModel.momentOccurred(.firstCheckIn)

        viewModel.openSettings()

        #expect(service.openedSettings == 1)
        #expect(!viewModel.isVisible)
    }
}
