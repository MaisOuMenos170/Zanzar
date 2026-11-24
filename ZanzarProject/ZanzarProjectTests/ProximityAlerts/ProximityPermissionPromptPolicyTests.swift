import Foundation
import Testing
@testable import ZanzarProject

@Suite("ProximityPermissionPromptPolicy")
struct ProximityPermissionPromptPolicyTests {
    private let policy = ProximityPermissionPromptPolicy()
    private let now = Date(timeIntervalSince1970: 1_800_000_000)
    private static let day: TimeInterval = 24 * 3_600

    @Test("The first time it is shown")
    func firstTime() {
        #expect(policy.shouldShow(ProximityPermissionPromptState(), now: now))
    }

    @Test("A 'Not now' is respected for two weeks")
    func spacing() {
        let thirteenDaysAgo = ProximityPermissionPromptState(
            timesShown: 1,
            lastShownAt: now.addingTimeInterval(-13 * Self.day)
        )
        let fifteenDaysAgo = ProximityPermissionPromptState(
            timesShown: 1,
            lastShownAt: now.addingTimeInterval(-15 * Self.day)
        )

        #expect(!policy.shouldShow(thirteenDaysAgo, now: now))
        #expect(policy.shouldShow(fifteenDaysAgo, now: now))
    }

    @Test("It stops after three times, however long ago")
    func cap() {
        let state = ProximityPermissionPromptState(timesShown: 3, lastShownAt: now.addingTimeInterval(-90 * Self.day))

        #expect(!policy.shouldShow(state, now: now))
    }

    @Test("Status: complete only with notifications and 'Always'; blocked when either was refused")
    func status() {
        let complete = ProximityPermissionStatus(notifications: .allowed, location: .always)
        let whileUsing = ProximityPermissionStatus(notifications: .allowed, location: .whenInUse)
        let noNotifications = ProximityPermissionStatus(notifications: .denied, location: .always)
        let noLocation = ProximityPermissionStatus(notifications: .allowed, location: .denied)

        #expect(complete.isComplete && !complete.isBlocked)
        #expect(!whileUsing.isComplete && !whileUsing.isBlocked)
        #expect(noNotifications.isBlocked)
        #expect(noLocation.isBlocked)
    }
}
