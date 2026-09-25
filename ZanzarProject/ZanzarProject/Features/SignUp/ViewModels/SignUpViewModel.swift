import Foundation
import Observation

@Observable
final class SignUpViewModel {
    private let service: SignUpServicing

    var username = ""
    var email = ""
    var password = ""

    var usernameError: String?
    var emailError: String?
    var passwordError: String?

    init(service: SignUpServicing = SignUpService()) {
        self.service = service
    }

    func submitTapped() {
        usernameError = username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "signUp.usernameField.errorRequired"
            : nil
        emailError = email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "signUp.emailField.errorRequired"
            : nil
        passwordError = password.isEmpty
            ? "signUp.passwordField.errorRequired"
            : nil

        guard usernameError == nil, emailError == nil, passwordError == nil else { return }

        // TODO: call service when backend is implemented
    }
}
