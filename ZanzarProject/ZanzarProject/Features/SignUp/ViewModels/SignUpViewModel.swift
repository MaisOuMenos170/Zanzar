import Foundation
import Observation

@Observable
final class SignUpViewModel {
    private let signUpService: SignUpServicing
    private let loginService: LoginServicing

    var username = ""
    var email = ""
    var password = ""
    /// Client-side gate only: the backend has no terms-acceptance field for registration.
    var acceptsTerms = false

    var usernameError: String?
    var emailError: String?
    var passwordError: String?
    var isLoading = false
    var submitError: String?
    var shouldNavigateToLogin = false
    private(set) var createdUsername: String?

    init(
        signUpService: SignUpServicing = SignUpService(),
        loginService: LoginServicing = LoginService()
    ) {
        self.signUpService = signUpService
        self.loginService = loginService
    }

    @discardableResult
    func validateFields() -> Bool {
        usernameError = AuthValidation.usernameError(
            for: username,
            emptyKey: "signUp.usernameField.errorEmpty",
            tooShortKey: "signUp.usernameField.errorTooShort"
        )
        emailError = AuthValidation.emailError(
            for: email,
            emptyKey: "signUp.emailField.errorEmpty",
            invalidKey: "signUp.emailField.errorInvalid"
        )
        passwordError = AuthValidation.passwordError(
            for: password,
            emptyKey: "signUp.passwordField.errorEmpty",
            tooShortKey: "signUp.passwordField.errorTooShort",
            invalidKey: "signUp.passwordField.errorInvalid"
        )

        return usernameError == nil && emailError == nil && passwordError == nil
    }

    /// Updates only the errors already on screen, so a field clears as soon as its value becomes valid.
    func refreshShownFieldErrors() {
        if usernameError != nil {
            usernameError = AuthValidation.usernameError(
                for: username,
                emptyKey: "signUp.usernameField.errorEmpty",
                tooShortKey: "signUp.usernameField.errorTooShort"
            )
        }
        if emailError != nil {
            emailError = AuthValidation.emailError(
                for: email,
                emptyKey: "signUp.emailField.errorEmpty",
                invalidKey: "signUp.emailField.errorInvalid"
            )
        }
        if passwordError != nil {
            passwordError = AuthValidation.passwordError(
                for: password,
                emptyKey: "signUp.passwordField.errorEmpty",
                tooShortKey: "signUp.passwordField.errorTooShort",
                invalidKey: "signUp.passwordField.errorInvalid"
            )
        }
    }

    func submit(using authSession: AuthSession) async -> Bool {
        guard !isLoading else { return false }

        submitError = nil
        shouldNavigateToLogin = false
        createdUsername = nil
        guard validateFields() else { return false }
        guard acceptsTerms else {
            submitError = String(localized: "signUp.submitError.termsRequired")
            return false
        }

        isLoading = true
        defer { isLoading = false }

        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            let created = try await signUpService.submitSignUp(
                SignUpRequest(
                    email: trimmedEmail,
                    username: trimmedUsername,
                    password: password
                )
            )
            createdUsername = created.username ?? trimmedUsername
        } catch let error as APIError {
            submitError = AuthErrorMapper.signUpMessage(for: error)
            return false
        } catch {
            submitError = String(localized: "signUp.submitError.generic")
            return false
        }

        do {
            let loginResponse = try await loginService.submitLogin(
                LoginRequest(email: trimmedEmail, password: password)
            )
            try authSession.signIn(accessToken: loginResponse.token, refreshToken: loginResponse.refreshToken)
            return true
        } catch {
            submitError = String(localized: "signUp.submitError.accountCreatedLoginRequired")
            shouldNavigateToLogin = true
            return false
        }
    }
}
