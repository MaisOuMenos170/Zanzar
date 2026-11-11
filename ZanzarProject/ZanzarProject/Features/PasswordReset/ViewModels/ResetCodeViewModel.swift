import Foundation
import Observation

@Observable
final class ResetCodeViewModel {
    static let codeLength = 6

    private let service: PasswordResetServicing

    let email: String
    var code = ""
    var codeError: String?
    var isLoading = false
    var isResending = false
    var submitError: String?

    init(email: String, service: PasswordResetServicing = PasswordResetService()) {
        self.email = email
        self.service = service
    }

    /// Keeps only digits, up to six, so pasting "123 456" or the whole email line still works.
    func sanitizeCode() {
        let digits = String(code.filter { $0.isASCII && $0.isNumber }.prefix(Self.codeLength))
        if digits != code {
            code = digits
        }
    }

    @discardableResult
    func validateFields() -> Bool {
        codeError = currentCodeError()
        return codeError == nil
    }

    func refreshShownFieldErrors() {
        if codeError != nil {
            codeError = currentCodeError()
        }
    }

    /// Exchanges the code for a reset token. Returns `nil` when the code was refused.
    func submit() async -> String? {
        guard !isLoading else { return nil }

        submitError = nil
        guard validateFields() else { return nil }

        isLoading = true
        defer { isLoading = false }

        do {
            return try await service.verify(VerifyResetRequest(email: email, code: code))
        } catch let error as APIError {
            submitError = AuthErrorMapper.resetCodeMessage(for: error)
            return nil
        } catch {
            submitError = L10n.string("passwordReset.code.error.generic")
            return nil
        }
    }

    /// Emails a new code; the previous one stops working.
    func resendCode() async -> Bool {
        guard !isResending, !isLoading else { return false }

        submitError = nil
        isResending = true
        defer { isResending = false }

        do {
            try await service.requestCode(email: email)
            code = ""
            codeError = nil
            return true
        } catch let error as APIError {
            submitError = AuthErrorMapper.forgotPasswordMessage(for: error)
            return false
        } catch {
            submitError = L10n.string("passwordReset.forgot.error.generic")
            return false
        }
    }

    private func currentCodeError() -> String? {
        if code.isEmpty {
            return "passwordReset.code.field.errorEmpty"
        }
        if code.count != Self.codeLength {
            return "passwordReset.code.field.errorInvalid"
        }
        return nil
    }
}
