import AuthenticationServices
import Foundation
import Testing
@testable import ZanzarProject

@MainActor
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
        mockService.submitLoginResult = .success(LoginResponse(token: "jwt-token", refreshToken: "refresh-token"))
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
        #expect(viewModel.submitError == L10n.string("login.submitError.invalidCredentials"))
    }

    @Test("configureAppleRequest asks for name and email and sends Apple only the hashed nonce")
    func configureAppleRequestSetsScopesAndHashedNonce() {
        let viewModel = LoginViewModel(service: MockLoginService())
        let request = ASAuthorizationAppleIDProvider().createRequest()

        viewModel.configureAppleRequest(request)

        #expect(request.requestedScopes == [.fullName, .email])
        let nonce = try? #require(request.nonce)
        #expect(nonce?.count == 64)
    }

    @Test("submitApple signs in and forwards token, raw nonce and name")
    @MainActor
    func submitAppleSignsIn() async throws {
        let mockService = MockLoginService()
        mockService.submitAppleLoginResult = .success(LoginResponse(token: "jwt-token", refreshToken: "refresh-token"))
        let authSession = AuthSession(keychain: InMemoryAuthTokenStore())
        let viewModel = LoginViewModel(service: mockService)
        let request = ASAuthorizationAppleIDProvider().createRequest()
        viewModel.configureAppleRequest(request)
        var name = PersonNameComponents()
        name.givenName = " Tiago "
        name.familyName = "Prestes"

        let didSubmit = await viewModel.submitApple(
            identityToken: Data("apple-token".utf8),
            fullName: name,
            using: authSession
        )

        #expect(didSubmit == true)
        #expect(authSession.isAuthenticated == true)
        #expect(viewModel.submitError == nil)
        let sent = try #require(mockService.lastAppleRequest)
        #expect(sent.identityToken == "apple-token")
        #expect(sent.fullName?.givenName == "Tiago")
        #expect(sent.fullName?.familyName == "Prestes")
        // Apple got the SHA-256 of what the backend receives.
        #expect(AppleSignInNonce(raw: sent.nonce).hashed == request.nonce)
    }

    @Test("submitApple omits the name when Apple did not send one (not the first authorization)")
    @MainActor
    func submitAppleWithoutName() async throws {
        let mockService = MockLoginService()
        mockService.submitAppleLoginResult = .success(LoginResponse(token: "jwt-token", refreshToken: "refresh-token"))
        let authSession = AuthSession(keychain: InMemoryAuthTokenStore())
        let viewModel = LoginViewModel(service: mockService)
        viewModel.configureAppleRequest(ASAuthorizationAppleIDProvider().createRequest())

        let didSubmit = await viewModel.submitApple(
            identityToken: Data("apple-token".utf8),
            fullName: PersonNameComponents(),
            using: authSession
        )

        #expect(didSubmit == true)
        #expect(mockService.lastAppleRequest?.fullName == nil)
    }

    @Test("submitApple fails without calling the backend when the identity token is missing")
    @MainActor
    func submitAppleWithoutTokenFails() async {
        let mockService = MockLoginService()
        let authSession = AuthSession(keychain: InMemoryAuthTokenStore())
        let viewModel = LoginViewModel(service: mockService)
        viewModel.configureAppleRequest(ASAuthorizationAppleIDProvider().createRequest())

        let didSubmit = await viewModel.submitApple(identityToken: nil, fullName: nil, using: authSession)

        #expect(didSubmit == false)
        #expect(mockService.lastAppleRequest == nil)
        #expect(authSession.isAuthenticated == false)
        #expect(viewModel.submitError == String(localized: "login.apple.error.generic"))
    }

    @Test("submitApple fails when the request was never configured (no nonce)")
    @MainActor
    func submitAppleWithoutNonceFails() async {
        let mockService = MockLoginService()
        let authSession = AuthSession(keychain: InMemoryAuthTokenStore())
        let viewModel = LoginViewModel(service: mockService)

        let didSubmit = await viewModel.submitApple(
            identityToken: Data("apple-token".utf8),
            fullName: nil,
            using: authSession
        )

        #expect(didSubmit == false)
        #expect(mockService.lastAppleRequest == nil)
    }

    @Test("submitApple spends the nonce, so a second submit is rejected")
    @MainActor
    func submitAppleNonceIsSingleUse() async {
        let mockService = MockLoginService()
        mockService.submitAppleLoginResult = .success(LoginResponse(token: "jwt-token", refreshToken: "refresh-token"))
        let authSession = AuthSession(keychain: InMemoryAuthTokenStore())
        let viewModel = LoginViewModel(service: mockService)
        viewModel.configureAppleRequest(ASAuthorizationAppleIDProvider().createRequest())
        _ = await viewModel.submitApple(identityToken: Data("apple-token".utf8), fullName: nil, using: authSession)

        let secondSubmit = await viewModel.submitApple(
            identityToken: Data("apple-token".utf8),
            fullName: nil,
            using: authSession
        )

        #expect(secondSubmit == false)
    }

    @Test("submitApple maps a backend rejection of the Apple token")
    @MainActor
    func submitAppleMapsInvalidToken() async {
        let mockService = MockLoginService()
        mockService.submitAppleLoginResult = .failure(APIError.httpStatus(401, message: "Invalid Apple identity token"))
        let authSession = AuthSession(keychain: InMemoryAuthTokenStore())
        let viewModel = LoginViewModel(service: mockService)
        viewModel.configureAppleRequest(ASAuthorizationAppleIDProvider().createRequest())

        let didSubmit = await viewModel.submitApple(
            identityToken: Data("apple-token".utf8),
            fullName: nil,
            using: authSession
        )

        #expect(didSubmit == false)
        #expect(authSession.isAuthenticated == false)
        #expect(viewModel.submitError == String(localized: "login.apple.error.invalidToken"))
    }

    @Test("completeAppleSignIn stays silent when the user dismisses the Apple sheet")
    @MainActor
    func completeAppleSignInCanceledIsSilent() async {
        let authSession = AuthSession(keychain: InMemoryAuthTokenStore())
        let viewModel = LoginViewModel(service: MockLoginService())

        let didSignIn = await viewModel.completeAppleSignIn(
            .failure(ASAuthorizationError(.canceled)),
            using: authSession
        )

        #expect(didSignIn == false)
        #expect(viewModel.submitError == nil)
    }

    @Test("completeAppleSignIn shows a generic error for other Apple failures")
    @MainActor
    func completeAppleSignInFailureShowsError() async {
        let authSession = AuthSession(keychain: InMemoryAuthTokenStore())
        let viewModel = LoginViewModel(service: MockLoginService())

        let didSignIn = await viewModel.completeAppleSignIn(
            .failure(ASAuthorizationError(.failed)),
            using: authSession
        )

        #expect(didSignIn == false)
        #expect(viewModel.submitError == String(localized: "login.apple.error.generic"))
    }

    @Test("submit ignores duplicate requests while loading")
    @MainActor
    func submitIgnoresDuplicateRequestsWhileLoading() async {
        let mockService = MockLoginService()
        mockService.submitLoginResult = .success(LoginResponse(token: "jwt-token", refreshToken: "refresh-token"))
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

final class MockLoginService: LoginServicing, @unchecked Sendable {
    var submitLoginResult: Result<LoginResponse, Error>?
    var submitAppleLoginResult: Result<LoginResponse, Error>?
    private(set) var lastAppleRequest: AppleLoginRequest?

    func submitLogin(_ request: LoginRequest) async throws -> LoginResponse {
        guard let result = submitLoginResult else {
            fatalError("MockLoginService.submitLoginResult not configured")
        }
        return try result.get()
    }

    func submitAppleLogin(_ request: AppleLoginRequest) async throws -> LoginResponse {
        lastAppleRequest = request
        guard let result = submitAppleLoginResult else {
            fatalError("MockLoginService.submitAppleLoginResult not configured")
        }
        return try result.get()
    }
}
