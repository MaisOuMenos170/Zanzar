import Foundation
import Testing
@testable import ZanzarProject

@MainActor
@Suite("OnboardingGate")
struct OnboardingGateTests {
    @Test("begin holds the auth flow and finish releases it")
    func beginAndFinish() {
        let gate = OnboardingGate()
        #expect(!gate.isActive)

        gate.begin()
        #expect(gate.isActive)

        gate.finish()
        #expect(!gate.isActive)
    }

    @Test("finish forgets the username of the account that was being created")
    func finishClearsUsername() {
        let gate = OnboardingGate()
        gate.begin()
        gate.username = "Maria"

        gate.finish()

        #expect(gate.username == nil)
    }

    @Test("a user without an avatar is sent to the editor")
    func resolvesNewUser() async {
        let gate = OnboardingGate()
        gate.begin()

        let needsAvatar = await gate.resolveAfterSignIn(
            avatarService: MockAvatarService(fetchResult: .success(nil)),
            userID: "user-1"
        )

        #expect(needsAvatar)
        #expect(gate.isActive)
    }

    @Test("a user with an avatar goes straight to the app")
    func resolvesReturningUser() async {
        let gate = OnboardingGate()
        gate.begin()

        let needsAvatar = await gate.resolveAfterSignIn(
            avatarService: MockAvatarService(fetchResult: .success(.placeholder)),
            userID: "user-1"
        )

        #expect(!needsAvatar)
        #expect(!gate.isActive)
    }

    @Test("a failed lookup never blocks the user")
    func lookupFailureDoesNotBlock() async {
        let gate = OnboardingGate()
        gate.begin()

        let needsAvatar = await gate.resolveAfterSignIn(
            avatarService: MockAvatarService(fetchResult: .failure(APIError.httpStatus(500, message: nil))),
            userID: "user-1"
        )

        #expect(!needsAvatar)
        #expect(!gate.isActive)
    }

    @Test("without a user id the gate is released")
    func missingUserID() async {
        let gate = OnboardingGate()
        gate.begin()

        let needsAvatar = await gate.resolveAfterSignIn(avatarService: MockAvatarService(), userID: nil)

        #expect(!needsAvatar)
        #expect(!gate.isActive)
    }
}
