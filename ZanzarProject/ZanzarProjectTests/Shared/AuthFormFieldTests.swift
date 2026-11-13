import Testing
@testable import ZanzarProject

struct AuthFormFieldTests {
    @Test func errorAppearingOnCleanFieldIsNew() {
        #expect(AuthFormField.isNewError(from: nil, to: "login.emailField.error"))
    }

    @Test func errorTextChangingWhileShownIsNotNew() {
        #expect(!AuthFormField.isNewError(from: "login.emailField.error", to: "login.emailField.other"))
    }

    @Test func errorClearingIsNotNew() {
        #expect(!AuthFormField.isNewError(from: "login.emailField.error", to: nil))
    }

    @Test func cleanFieldStayingCleanIsNotNew() {
        #expect(!AuthFormField.isNewError(from: nil, to: nil))
    }
}
