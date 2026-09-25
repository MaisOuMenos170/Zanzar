import Testing
@testable import ZanzarProject

@Suite("SignUpViewModel")
struct SignUpViewModelTests {
    @Test("submit with empty fields explains each missing field")
    func submitWithEmptyFieldsSetsErrors() {
        let viewModel = SignUpViewModel(service: MockSignUpService())

        let didSubmit = viewModel.submitTapped()

        #expect(didSubmit == false)
        #expect(viewModel.usernameError == "signUp.usernameField.errorEmpty")
        #expect(viewModel.emailError == "signUp.emailField.errorEmpty")
        #expect(viewModel.passwordError == "signUp.passwordField.errorEmpty")
    }

    @Test("submit with invalid email explains the format problem")
    func submitWithInvalidEmailSetsInvalidError() {
        let viewModel = SignUpViewModel(service: MockSignUpService())
        viewModel.username = "zanzar"
        viewModel.email = "email-invalido"
        viewModel.password = "secret123"

        let didSubmit = viewModel.submitTapped()

        #expect(didSubmit == false)
        #expect(viewModel.usernameError == nil)
        #expect(viewModel.emailError == "signUp.emailField.errorInvalid")
        #expect(viewModel.passwordError == nil)
    }

    @Test("submit with short password explains the length requirement")
    func submitWithShortPasswordSetsTooShortError() {
        let viewModel = SignUpViewModel(service: MockSignUpService())
        viewModel.username = "zanzar"
        viewModel.email = "user@example.com"
        viewModel.password = "123"

        let didSubmit = viewModel.submitTapped()

        #expect(didSubmit == false)
        #expect(viewModel.passwordError == "signUp.passwordField.errorTooShort")
    }

    @Test("submit with valid fields clears validation errors")
    func submitWithValidFieldsClearsErrors() {
        let viewModel = SignUpViewModel(service: MockSignUpService())
        viewModel.username = "zanzar"
        viewModel.email = "user@example.com"
        viewModel.password = "secret123"

        let didSubmit = viewModel.submitTapped()

        #expect(didSubmit == true)
        #expect(viewModel.usernameError == nil)
        #expect(viewModel.emailError == nil)
        #expect(viewModel.passwordError == nil)
    }
}

final class MockSignUpService: SignUpServicing {
    var submitSignUpResult: Result<SignUpResponse, Error>?

    func submitSignUp(_ request: SignUpRequest) async throws -> SignUpResponse {
        guard let result = submitSignUpResult else {
            fatalError("MockSignUpService.submitSignUpResult not configured")
        }
        return try result.get()
    }
}
