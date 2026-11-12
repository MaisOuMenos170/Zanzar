import Testing
@testable import ZanzarProject

/// The main button of each form stays off until every input has something in it.
@MainActor
@Suite("Submit availability")
struct SubmitAvailabilityTests {
    @Test("login needs an email and a password")
    func login() {
        let viewModel = LoginViewModel(service: MockLoginService())
        #expect(viewModel.canSubmit == false)

        viewModel.email = "ana@example.com"
        #expect(viewModel.canSubmit == false)

        viewModel.password = "secret12"
        #expect(viewModel.canSubmit)
    }

    @Test("a login email with only spaces does not count")
    func loginIgnoresBlankEmail() {
        let viewModel = LoginViewModel(service: MockLoginService())
        viewModel.email = "   "
        viewModel.password = "secret12"

        #expect(viewModel.canSubmit == false)
    }

    @Test("sign up needs a name, an email and a password")
    func signUp() {
        let viewModel = SignUpViewModel()
        #expect(viewModel.canSubmit == false)

        viewModel.username = "Ana"
        viewModel.email = "ana@example.com"
        #expect(viewModel.canSubmit == false)

        viewModel.password = "secret12"
        #expect(viewModel.canSubmit)
    }

    @Test("forgot password needs an email")
    func forgotPassword() {
        let viewModel = ForgotPasswordViewModel()
        #expect(viewModel.canSubmit == false)

        viewModel.email = "ana@example.com"
        #expect(viewModel.canSubmit)
    }

    @Test("the reset code needs all of its digits")
    func resetCode() {
        let viewModel = ResetCodeViewModel(email: "ana@example.com")
        #expect(viewModel.canSubmit == false)

        viewModel.code = "12345"
        #expect(viewModel.canSubmit == false)

        viewModel.code = "123456"
        #expect(viewModel.canSubmit)
    }

    @Test("the new password needs both fields")
    func newPassword() {
        let viewModel = NewPasswordViewModel(resetToken: "token")
        #expect(viewModel.canSubmit == false)

        viewModel.password = "secret12"
        #expect(viewModel.canSubmit == false)

        viewModel.confirmation = "secret12"
        #expect(viewModel.canSubmit)
    }
}
