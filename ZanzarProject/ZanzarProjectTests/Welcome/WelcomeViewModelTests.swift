import Testing
@testable import ZanzarProject

@Suite("WelcomeViewModel")
struct WelcomeViewModelTests {
    @Test("auth actions are safe to call before backend wiring")
    func authActionsDoNotThrow() {
        let viewModel = WelcomeViewModel(service: MockWelcomeService())

        viewModel.createAccountTapped()
        viewModel.loginTapped()
    }
}

final class MockWelcomeService: WelcomeServicing {
    var submitWelcomeResult: Result<WelcomeResponse, Error>?

    func submitWelcome(_ request: WelcomeRequest) async throws -> WelcomeResponse {
        guard let result = submitWelcomeResult else {
            fatalError("MockWelcomeService.submitWelcomeResult not configured")
        }
        return try result.get()
    }
}
