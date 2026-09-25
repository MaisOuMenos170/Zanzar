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

    func submitTapped() {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        emailError = trimmedEmail.isEmpty || !trimmedEmail.contains("@")
            ? "login.emailField.errorInvalid"
            : nil
        passwordError = password.isEmpty
            ? "login.passwordField.errorInvalid"
            : nil

        guard emailError == nil, passwordError == nil else { return }

        // TODO: call service when backend is implemented
    }
}
