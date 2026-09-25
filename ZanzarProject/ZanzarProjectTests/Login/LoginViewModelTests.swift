import Testing
@testable import ZanzarProject

@Suite("LoginViewModel")
struct LoginViewModelTests {
    @Test("submit with empty fields sets validation errors")
    func submitWithEmptyFieldsSetsErrors() {
        let viewModel = LoginViewModel(service: MockLoginService())

        viewModel.submitTapped()

        #expect(viewModel.emailError == "login.emailField.errorInvalid")
        #expect(viewModel.passwordError == "login.passwordField.errorInvalid")
    }

    @Test("submit with valid fields clears validation errors")
    func submitWithValidFieldsClearsErrors() {
        let viewModel = LoginViewModel(service: MockLoginService())
        viewModel.email = "user@example.com"
        viewModel.password = "secret"

        viewModel.submitTapped()

        #expect(viewModel.emailError == nil)
        #expect(viewModel.passwordError == nil)
    }
}

final class MockLoginService: LoginServicing {
    var submitLoginResult: Result<LoginResponse, Error>?

    func submitLogin(_ request: LoginRequest) async throws -> LoginResponse {
        guard let result = submitLoginResult else {
            fatalError("MockLoginService.submitLoginResult not configured")
        }
        return try result.get()
    }
}
