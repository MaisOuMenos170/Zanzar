import Foundation
import Observation

@Observable
final class SignUpViewModel {
    private let service: SignUpServicing

    private static let minimumUsernameLength = 2
    private static let minimumPasswordLength = 6

    var username = ""
    var email = ""
    var password = ""

    var usernameError: String?
    var emailError: String?
    var passwordError: String?

    init(service: SignUpServicing = SignUpService()) {
        self.service = service
    }

    @discardableResult
    func submitTapped() -> Bool {
        usernameError = validateUsername()
        emailError = validateEmail()
        passwordError = validatePassword()

        guard usernameError == nil, emailError == nil, passwordError == nil else {
            return false
        }

        // TODO: call service when backend is implemented
        return true
    }

    private func validateUsername() -> String? {
        let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            return "signUp.usernameField.errorEmpty"
        }

        if trimmed.count < Self.minimumUsernameLength {
            return "signUp.usernameField.errorTooShort"
        }

        return nil
    }

    private func validateEmail() -> String? {
        AuthValidation.emailError(
            for: email,
            emptyKey: "signUp.emailField.errorEmpty",
            invalidKey: "signUp.emailField.errorInvalid"
        )
    }

    private func validatePassword() -> String? {
        if password.isEmpty {
            return "signUp.passwordField.errorEmpty"
        }

        if password.count < Self.minimumPasswordLength {
            return "signUp.passwordField.errorTooShort"
        }

        return nil
    }

}
