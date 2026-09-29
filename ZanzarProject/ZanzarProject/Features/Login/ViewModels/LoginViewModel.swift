import Foundation
import Observation

@Observable
final class LoginViewModel {
    private let service: LoginServicing

    var email = ""
    var password = ""

    var emailError: String?
    var passwordError: String?
    var isLoading = false
    var submitError: String?

    init(service: LoginServicing = LoginService()) {
        self.service = service
    }

    @discardableResult
    func validateFields() -> Bool {
        emailError = AuthValidation.emailError(
            for: email,
            emptyKey: "login.emailField.errorEmpty",
            invalidKey: "login.emailField.errorInvalid"
        )
        passwordError = password.isEmpty
            ? "login.passwordField.errorEmpty"
            : nil

        return emailError == nil && passwordError == nil
    }

    func submit(using authSession: AuthSession) async -> Bool {
        submitError = nil
        guard validateFields() else { return false }

        isLoading = true
        defer { isLoading = false }

        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            let response = try await service.submitLogin(
                LoginRequest(email: trimmedEmail, password: password)
            )
            try authSession.signIn(token: response.token)
            return true
        } catch let error as APIError {
            submitError = Self.errorMessage(for: error)
            return false
        } catch {
            submitError = String(localized: "login.submitError.generic")
            return false
        }
    }

    private static func errorMessage(for error: APIError) -> String {
        switch error {
        case .httpStatus(401, _):
            String(localized: "login.submitError.invalidCredentials")
        case .httpStatus(_, let message) where message?.isEmpty == false:
            message!
        case .decodingFailed, .invalidResponse:
            String(localized: "login.submitError.generic")
        case .httpStatus:
            String(localized: "login.submitError.generic")
        }
    }
}
