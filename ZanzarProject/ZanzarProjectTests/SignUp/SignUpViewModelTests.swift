import Testing
@testable import ZanzarProject

@Suite("SignUpViewModel")
struct SignUpViewModelTests {
    @Test("submit with empty fields sets validation errors")
    func submitWithEmptyFieldsSetsErrors() {
        let viewModel = SignUpViewModel(service: MockSignUpService())

        viewModel.submitTapped()

        #expect(viewModel.usernameError == "signUp.usernameField.errorRequired")
        #expect(viewModel.emailError == "signUp.emailField.errorRequired")
        #expect(viewModel.passwordError == "signUp.passwordField.errorRequired")
    }

    @Test("submit with valid fields clears validation errors")
    func submitWithValidFieldsClearsErrors() {
        let viewModel = SignUpViewModel(service: MockSignUpService())
        viewModel.username = "zanzar"
        viewModel.email = "user@example.com"
        viewModel.password = "secret"

        viewModel.submitTapped()

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
