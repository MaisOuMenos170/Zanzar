import Testing
@testable import ZanzarProject

@Suite("LoginViewModel")
struct LoginViewModelTests {
    @Test("submit with empty fields explains each missing field")
    func submitWithEmptyFieldsSetsErrors() {
        let viewModel = LoginViewModel(service: MockLoginService())

        let didSubmit = viewModel.submitTapped()

        #expect(didSubmit == false)
        #expect(viewModel.emailError == "login.emailField.errorEmpty")
        #expect(viewModel.passwordError == "login.passwordField.errorEmpty")
    }

    @Test("submit with invalid email explains the format problem")
    func submitWithInvalidEmailSetsInvalidError() {
        let viewModel = LoginViewModel(service: MockLoginService())
        viewModel.email = "email-invalido"
        viewModel.password = "secret"

        let didSubmit = viewModel.submitTapped()

        #expect(didSubmit == false)
        #expect(viewModel.emailError == "login.emailField.errorInvalid")
        #expect(viewModel.passwordError == nil)
    }

    @Test("submit with valid fields succeeds")
    func submitWithValidFieldsSucceeds() {
        let viewModel = LoginViewModel(service: MockLoginService())
        viewModel.email = "user@example.com"
        viewModel.password = "secret"

        let didSubmit = viewModel.submitTapped()

        #expect(didSubmit == true)
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
