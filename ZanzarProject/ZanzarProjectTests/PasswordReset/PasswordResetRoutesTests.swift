import SwiftUI
import Testing
@testable import ZanzarProject

@MainActor
@Suite("Password reset routes")
struct PasswordResetRoutesTests {
    @Test("the reset screens are pushed in order and the success screen leaves the stack on the login screen")
    func sequenceEndsOnLogin() {
        let coordinator = AppCoordinator()

        coordinator.push(.forgotPassword)
        coordinator.push(.resetCode(email: "ana@example.com"))
        coordinator.push(.codeVerified(resetToken: "token"))
        coordinator.push(.newPassword(resetToken: "token"))
        coordinator.push(.passwordResetSuccess)
        #expect(coordinator.path.count == 5)

        coordinator.returnToLogin()
        #expect(coordinator.path.count == 1)
    }

    @Test("routes with the same token are equal, so the path can compare them")
    func routesAreHashable() {
        #expect(Route.codeVerified(resetToken: "a") == Route.codeVerified(resetToken: "a"))
        #expect(Route.codeVerified(resetToken: "a") != Route.codeVerified(resetToken: "b"))
    }
}
