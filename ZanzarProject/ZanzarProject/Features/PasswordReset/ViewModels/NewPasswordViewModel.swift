import Foundation
import Observation

@Observable
final class NewPasswordViewModel {
    private let service: PasswordResetServicing
    private let resetToken: String

    var password = ""
    var confirmation = ""
    var passwordError: String?
    var confirmationError: String?
    var isLoading = false
    var submitError: String?

    init(resetToken: String, service: PasswordResetServicing = PasswordResetService()) {
        self.resetToken = resetToken
        self.service = service
    }

    @discardableResult
    func validateFields() -> Bool {
        passwordError = currentPasswordError()
        confirmationError = currentConfirmationError()
        return passwordError == nil && confirmationError == nil
    }

    func refreshShownFieldErrors() {
        if passwordError != nil {
            passwordError = currentPasswordError()
        }
        if confirmationError != nil {
            confirmationError = currentConfirmationError()
        }
    }

    func submit() async -> Bool {
        guard !isLoading else { return false }

        submitError = nil
        guard validateFields() else { return false }

        isLoading = true
        defer { isLoading = false }

        do {
            try await service.resetPassword(resetToken: resetToken, newPassword: password)
            return true
        } catch let error as APIError {
            submitError = AuthErrorMapper.newPasswordMessage(for: error)
            return false
        } catch {
            submitError = L10n.string("passwordReset.newPassword.error.generic")
            return false
        }
    }

    private func currentPasswordError() -> String? {
        AuthValidation.passwordError(
            for: password,
            emptyKey: "signUp.passwordField.errorEmpty",
            tooShortKey: "signUp.passwordField.errorTooShort",
            invalidKey: "signUp.passwordField.errorInvalid"
        )
    }

    private func currentConfirmationError() -> String? {
        if confirmation.isEmpty {
            return "passwordReset.confirmPassword.field.errorEmpty"
        }
        if confirmation != password {
            return "passwordReset.confirmPassword.field.errorMismatch"
        }
        return nil
    }
}
