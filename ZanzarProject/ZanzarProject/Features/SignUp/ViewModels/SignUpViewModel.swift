import Foundation
import Observation

@Observable
final class SignUpViewModel {
    private let signUpService: SignUpServicing
    private let loginService: LoginServicing

    var username = ""
    var email = ""
    var password = ""

    var usernameError: String?
    var emailError: String?
    var passwordError: String?
    var isLoading = false
    var submitError: String?
    var shouldNavigateToLogin = false

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
        guard validateFields() else { return false }

        isLoading = true
        defer { isLoading = false }

        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            _ = try await signUpService.submitSignUp(
                SignUpRequest(
                    email: trimmedEmail,
                    username: trimmedUsername,
                    password: password
                )
            )
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
            try authSession.signIn(token: loginResponse.token)
            return true
        } catch {
            submitError = String(localized: "signUp.submitError.accountCreatedLoginRequired")
            shouldNavigateToLogin = true
            return false
        }
    }
}
