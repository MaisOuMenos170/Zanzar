import Foundation
import Testing
@testable import ZanzarProject

@Suite("SignUpViewModel")
struct SignUpViewModelTests {
    @Test("validate with empty fields explains each missing field")
    func validateWithEmptyFieldsSetsErrors() {
        let viewModel = SignUpViewModel(
            signUpService: MockSignUpService(),
            loginService: MockLoginService()
        )

        let isValid = viewModel.validateFields()

        #expect(isValid == false)
        #expect(viewModel.usernameError == "signUp.usernameField.errorEmpty")
        #expect(viewModel.emailError == "signUp.emailField.errorEmpty")
        #expect(viewModel.passwordError == "signUp.passwordField.errorEmpty")
    }

    @Test("validate with invalid email explains the format problem")
    func validateWithInvalidEmailSetsInvalidError() {
        let viewModel = SignUpViewModel(
            signUpService: MockSignUpService(),
            loginService: MockLoginService()
        )
        viewModel.username = "zanzar"
        viewModel.email = "email-invalido"
        viewModel.password = "secret123"

        let isValid = viewModel.validateFields()

        #expect(isValid == false)
        #expect(viewModel.usernameError == nil)
        #expect(viewModel.emailError == "signUp.emailField.errorInvalid")
        #expect(viewModel.passwordError == nil)
    }

    @Test("validate with short username explains the length requirement")
    func validateWithShortUsernameSetsTooShortError() {
        let viewModel = SignUpViewModel(
            signUpService: MockSignUpService(),
            loginService: MockLoginService()
        )
        viewModel.username = "za"
        viewModel.email = "user@example.com"
        viewModel.password = "secret123"

        let isValid = viewModel.validateFields()

        #expect(isValid == false)
        #expect(viewModel.usernameError == "signUp.usernameField.errorTooShort")
    }

    @Test("validate with short password explains the length requirement")
    func validateWithShortPasswordSetsTooShortError() {
        let viewModel = SignUpViewModel(
            signUpService: MockSignUpService(),
            loginService: MockLoginService()
        )
        viewModel.username = "zanzar"
        viewModel.email = "user@example.com"
        viewModel.password = "123"

        let isValid = viewModel.validateFields()

        #expect(isValid == false)
        #expect(viewModel.passwordError == "signUp.passwordField.errorTooShort")
    }

    @Test("validate with password missing letter and number explains the format requirement")
    func validateWithInvalidPasswordPatternSetsInvalidError() {
        let viewModel = SignUpViewModel(
            signUpService: MockSignUpService(),
            loginService: MockLoginService()
        )
        viewModel.username = "zanzar"
        viewModel.email = "user@example.com"
        viewModel.password = "12345678"

        let isValid = viewModel.validateFields()

        #expect(isValid == false)
        #expect(viewModel.passwordError == "signUp.passwordField.errorInvalid")
    }

    @Test("validate with valid fields clears validation errors")
    func validateWithValidFieldsClearsErrors() {
        let viewModel = SignUpViewModel(
            signUpService: MockSignUpService(),
            loginService: MockLoginService()
        )
        viewModel.username = "zanzar"
        viewModel.email = "user@example.com"
        viewModel.password = "secret123"

        let isValid = viewModel.validateFields()

        #expect(isValid == true)
        #expect(viewModel.usernameError == nil)
        #expect(viewModel.emailError == nil)
        #expect(viewModel.passwordError == nil)
    }

    @Test("submit signs in after register and login succeed")
    @MainActor
    func submitSignsInAfterRegisterAndLoginSucceed() async {
        let signUpService = MockSignUpService()
        signUpService.submitSignUpResult = .success(SignUpResponse(id: "user-id"))
        let loginService = MockLoginService()
        loginService.submitLoginResult = .success(LoginResponse(token: "jwt-token"))
        let authSession = AuthSession(keychain: InMemoryAuthTokenStore())
        let viewModel = SignUpViewModel(
            signUpService: signUpService,
            loginService: loginService
        )
        viewModel.username = "zanzar"
        viewModel.email = "user@example.com"
        viewModel.password = "secret123"

        let didSubmit = await viewModel.submit(using: authSession)

        #expect(didSubmit == true)
        #expect(authSession.isAuthenticated == true)
        #expect(viewModel.submitError == nil)
    }

    @Test("submit maps email already in use error")
    @MainActor
    func submitMapsEmailAlreadyInUseError() async {
        let signUpService = MockSignUpService()
        signUpService.submitSignUpResult = .failure(APIError.httpStatus(409, message: "Email already in use"))
        let viewModel = SignUpViewModel(
            signUpService: signUpService,
            loginService: MockLoginService()
        )
        viewModel.username = "zanzar"
        viewModel.email = "user@example.com"
        viewModel.password = "secret123"

        let didSubmit = await viewModel.submit(using: AuthSession(keychain: InMemoryAuthTokenStore()))

        #expect(didSubmit == false)
        #expect(viewModel.submitError == String(localized: "signUp.submitError.emailInUse"))
    }

    @Test("submit prompts login when register succeeds but login fails")
    @MainActor
    func submitPromptsLoginWhenRegisterSucceedsButLoginFails() async {
        let signUpService = MockSignUpService()
        signUpService.submitSignUpResult = .success(SignUpResponse(id: "user-id"))
        let loginService = MockLoginService()
        loginService.submitLoginResult = .failure(APIError.httpStatus(500, message: "Internal Server Error"))
        let viewModel = SignUpViewModel(
            signUpService: signUpService,
            loginService: loginService
        )
        viewModel.username = "zanzar"
        viewModel.email = "user@example.com"
        viewModel.password = "secret123"

        let didSubmit = await viewModel.submit(using: AuthSession(keychain: InMemoryAuthTokenStore()))

        #expect(didSubmit == false)
        #expect(viewModel.shouldNavigateToLogin == true)
        #expect(viewModel.submitError == String(localized: "signUp.submitError.accountCreatedLoginRequired"))
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
