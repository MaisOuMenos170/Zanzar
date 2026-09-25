import Foundation
import Observation

@Observable
final class LoginViewModel {
    private let service: LoginServicing

    var email = ""
    var password = ""

    var emailError: String?
    var passwordError: String?

    init(service: LoginServicing = LoginService()) {
        self.service = service
    }

    @discardableResult
    func submitTapped() -> Bool {
        emailError = AuthValidation.emailError(
            for: email,
            emptyKey: "login.emailField.errorEmpty",
            invalidKey: "login.emailField.errorInvalid"
        )
        passwordError = password.isEmpty
            ? "login.passwordField.errorEmpty"
            : nil

        guard emailError == nil, passwordError == nil else {
            return false
        }

        // TODO: call service when backend is implemented
        return true
    }
}
