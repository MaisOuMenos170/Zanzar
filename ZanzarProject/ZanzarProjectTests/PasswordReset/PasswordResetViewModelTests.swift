import Foundation
import Testing
@testable import ZanzarProject

@MainActor
@Suite("Password reset view models")
struct PasswordResetViewModelTests {
    // MARK: - ForgotPasswordViewModel

    @Test("forgot password validates the email before calling the backend")
    func forgotValidatesEmail() async {
        let service = FakePasswordResetService()
        let viewModel = ForgotPasswordViewModel(service: service)
        viewModel.email = "not-an-email"

        let sentTo = await viewModel.submit()

        #expect(sentTo == nil)
        #expect(viewModel.emailError == "login.emailField.errorInvalid")
        #expect(service.requestedEmails.isEmpty)
    }

    @Test("forgot password sends the trimmed email and returns it")
    func forgotSendsTrimmedEmail() async {
        let service = FakePasswordResetService()
        let viewModel = ForgotPasswordViewModel(service: service)
        viewModel.email = "  ana@example.com "

        let sentTo = await viewModel.submit()

        #expect(sentTo == "ana@example.com")
        #expect(service.requestedEmails == ["ana@example.com"])
        #expect(viewModel.isLoading == false)
        #expect(viewModel.submitError == nil)
    }

    @Test("forgot password shows the rate limit message on 429")
    func forgotRateLimited() async {
        let service = FakePasswordResetService()
        service.requestCodeError = APIError.rateLimited(retryAfter: 600)
        let viewModel = ForgotPasswordViewModel(service: service)
        viewModel.email = "ana@example.com"

        let sentTo = await viewModel.submit()

        #expect(sentTo == nil)
        #expect(viewModel.submitError == L10n.string("error.rateLimited.message", 10))
    }

    // MARK: - ResetCodeViewModel

    @Test("the code keeps only the first six digits")
    func sanitizesCode() {
        let viewModel = ResetCodeViewModel(email: "ana@example.com", service: FakePasswordResetService())
        viewModel.code = "12 3-45a678"

        viewModel.sanitizeCode()

        #expect(viewModel.code == "123456")
    }

    @Test("a short code is refused before calling the backend")
    func shortCode() async {
        let service = FakePasswordResetService()
        let viewModel = ResetCodeViewModel(email: "ana@example.com", service: service)
        viewModel.code = "123"

        let token = await viewModel.submit()

        #expect(token == nil)
        #expect(viewModel.codeError == "passwordReset.code.field.errorInvalid")
        #expect(service.verifyRequests.isEmpty)
    }

    @Test("a valid code is exchanged for the reset token")
    func verifiesCode() async {
        let service = FakePasswordResetService()
        service.verifyResult = .success("reset-123")
        let viewModel = ResetCodeViewModel(email: "ana@example.com", service: service)
        viewModel.code = "123456"

        let token = await viewModel.submit()

        #expect(token == "reset-123")
        #expect(service.verifyRequests == [VerifyResetRequest(email: "ana@example.com", code: "123456")])
    }

    @Test("a refused code (400) explains that it is invalid or expired")
    func refusedCode() async {
        let service = FakePasswordResetService()
        service.verifyResult = .failure(APIError.httpStatus(400, message: "Invalid or expired code"))
        let viewModel = ResetCodeViewModel(email: "ana@example.com", service: service)
        viewModel.code = "123456"

        let token = await viewModel.submit()

        #expect(token == nil)
        #expect(viewModel.submitError == L10n.string("passwordReset.code.error.invalidOrExpired"))
    }

    @Test("resending asks for a new code for the same email and clears the field")
    func resendsCode() async {
        let service = FakePasswordResetService()
        let viewModel = ResetCodeViewModel(email: "ana@example.com", service: service)
        viewModel.code = "111"

        let resent = await viewModel.resendCode()

        #expect(resent)
        #expect(service.requestedEmails == ["ana@example.com"])
        #expect(viewModel.code.isEmpty)
        #expect(viewModel.isResending == false)
    }

    // MARK: - NewPasswordViewModel

    @Test("the new password follows the sign-up rules and must be confirmed")
    func validatesNewPassword() async {
        let service = FakePasswordResetService()
        let viewModel = NewPasswordViewModel(resetToken: "reset-123", service: service)
        viewModel.password = "onlyletters"
        viewModel.confirmation = "different1"

        let saved = await viewModel.submit()

        #expect(saved == false)
        #expect(viewModel.passwordError == "signUp.passwordField.errorInvalid")
        #expect(viewModel.confirmationError == "passwordReset.confirmPassword.field.errorMismatch")
        #expect(service.resetCalls.isEmpty)
    }

    @Test("a valid new password is sent with the reset token")
    func savesNewPassword() async {
        let service = FakePasswordResetService()
        let viewModel = NewPasswordViewModel(resetToken: "reset-123", service: service)
        viewModel.password = "nova1234"
        viewModel.confirmation = "nova1234"

        let saved = await viewModel.submit()

        #expect(saved)
        #expect(service.resetCalls.map(\.resetToken) == ["reset-123"])
        #expect(service.resetCalls.map(\.newPassword) == ["nova1234"])
    }

    @Test("an expired reset token (401) asks for a new code")
    func expiredResetToken() async {
        let service = FakePasswordResetService()
        service.resetError = APIError.httpStatus(401, message: "Invalid reset token")
        let viewModel = NewPasswordViewModel(resetToken: "reset-123", service: service)
        viewModel.password = "nova1234"
        viewModel.confirmation = "nova1234"

        let saved = await viewModel.submit()

        #expect(saved == false)
        #expect(viewModel.submitError == L10n.string("passwordReset.newPassword.error.expired"))
    }
}
