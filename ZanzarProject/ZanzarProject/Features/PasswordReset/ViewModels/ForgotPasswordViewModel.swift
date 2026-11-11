import Foundation
import Observation

@Observable
final class ForgotPasswordViewModel {
    private let service: PasswordResetServicing

    var email = ""
    var emailError: String?
    var isLoading = false
    var submitError: String?

    init(service: PasswordResetServicing = PasswordResetService()) {
        self.service = service
    }

    @discardableResult
    func validateFields() -> Bool {
        emailError = currentEmailError()
        return emailError == nil
    }

    /// Updates only the error already on screen, so the field clears as soon as its value becomes valid.
    func refreshShownFieldErrors() {
        if emailError != nil {
            emailError = currentEmailError()
        }
    }

    /// Asks the backend to email a code. Returns the email it was sent to, or `nil` when nothing was sent.
    func submit() async -> String? {
        guard !isLoading else { return nil }

        submitError = nil
        guard validateFields() else { return nil }

        isLoading = true
        defer { isLoading = false }

        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            try await service.requestCode(email: trimmedEmail)
            return trimmedEmail
        } catch let error as APIError {
            submitError = AuthErrorMapper.forgotPasswordMessage(for: error)
            return nil
        } catch {
            submitError = L10n.string("passwordReset.forgot.error.generic")
            return nil
        }
    }

    private func currentEmailError() -> String? {
        AuthValidation.emailError(
            for: email,
            emptyKey: "login.emailField.errorEmpty",
            invalidKey: "login.emailField.errorInvalid"
        )
    }
}
