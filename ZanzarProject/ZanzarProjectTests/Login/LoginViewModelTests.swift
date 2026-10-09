import Foundation
import Testing
@testable import ZanzarProject

@Suite("LoginViewModel")
struct LoginViewModelTests {
    @Test("validate with empty fields explains each missing field")
    func validateWithEmptyFieldsSetsErrors() {
        let viewModel = LoginViewModel(service: MockLoginService())

        let isValid = viewModel.validateFields()

        #expect(isValid == false)
        #expect(viewModel.emailError == "login.emailField.errorEmpty")
        #expect(viewModel.passwordError == "login.passwordField.errorEmpty")
    }

    @Test("validate with invalid email explains the format problem")
    func validateWithInvalidEmailSetsInvalidError() {
        let viewModel = LoginViewModel(service: MockLoginService())
        viewModel.email = "email-invalido"
        viewModel.password = "secret12"

        let isValid = viewModel.validateFields()

        #expect(isValid == false)
        #expect(viewModel.emailError == "login.emailField.errorInvalid")
        #expect(viewModel.passwordError == nil)
    }

    @Test("validate with valid fields succeeds")
    func validateWithValidFieldsSucceeds() {
        let viewModel = LoginViewModel(service: MockLoginService())
        viewModel.email = "user@example.com"
        viewModel.password = "secret12"

        let isValid = viewModel.validateFields()

        #expect(isValid == true)
        #expect(viewModel.emailError == nil)
        #expect(viewModel.passwordError == nil)
    }

    @Test("a shown field error clears once that field becomes valid")
    func shownFieldErrorClearsWhenValueBecomesValid() {
        let viewModel = LoginViewModel(service: MockLoginService())
        #expect(viewModel.validateFields() == false)

        viewModel.email = "user@example.com"
        viewModel.refreshShownFieldErrors()

        #expect(viewModel.emailError == nil)
        #expect(viewModel.passwordError == "login.passwordField.errorEmpty")
    }

    @Test("submit signs in when login succeeds")
    @MainActor
    func submitSignsInWhenLoginSucceeds() async {
        let mockService = MockLoginService()
        mockService.submitLoginResult = .success(LoginResponse(token: "jwt-token"))
        let authSession = AuthSession(keychain: InMemoryAuthTokenStore())
        let viewModel = LoginViewModel(service: mockService)
        viewModel.email = "user@example.com"
        viewModel.password = "secret12"

        let didSubmit = await viewModel.submit(using: authSession)

        #expect(didSubmit == true)
        #expect(authSession.isAuthenticated == true)
        #expect(viewModel.submitError == nil)
    }

    @Test("submit maps invalid credentials error")
    @MainActor
    func submitMapsInvalidCredentialsError() async {
        let mockService = MockLoginService()
        mockService.submitLoginResult = .failure(APIError.httpStatus(401, message: "Invalid credentials"))
        let authSession = AuthSession(keychain: InMemoryAuthTokenStore())
        let viewModel = LoginViewModel(service: mockService)
        viewModel.email = "user@example.com"
        viewModel.password = "secret12"

        let didSubmit = await viewModel.submit(using: authSession)

        #expect(didSubmit == false)
        #expect(authSession.isAuthenticated == false)
        #expect(viewModel.submitError == String(localized: "login.submitError.invalidCredentials"))
    }

    @Test("submit ignores duplicate requests while loading")
    @MainActor
    func submitIgnoresDuplicateRequestsWhileLoading() async {
        let mockService = MockLoginService()
        mockService.submitLoginResult = .success(LoginResponse(token: "jwt-token"))
        let authSession = AuthSession(keychain: InMemoryAuthTokenStore())
        let viewModel = LoginViewModel(service: mockService)
        viewModel.email = "user@example.com"
        viewModel.password = "secret12"
        viewModel.isLoading = true

        let didSubmit = await viewModel.submit(using: authSession)

        #expect(didSubmit == false)
        #expect(authSession.isAuthenticated == false)
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
