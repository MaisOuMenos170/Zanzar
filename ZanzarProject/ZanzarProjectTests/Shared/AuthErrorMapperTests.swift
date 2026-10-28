import Foundation
import Testing
@testable import ZanzarProject

@Suite("AuthErrorMapper")
struct AuthErrorMapperTests {
    @Test("maps login 401 to invalid credentials")
    func loginUnauthorized() {
        let message = AuthErrorMapper.loginMessage(for: .httpStatus(401, message: "bad"))
        #expect(message == L10n.string("login.submitError.invalidCredentials"))
    }

    @Test("maps sign-up 409 to email in use")
    func signUpConflict() {
        let message = AuthErrorMapper.signUpMessage(for: .httpStatus(409, message: "exists"))
        #expect(message == L10n.string("signUp.submitError.emailInUse"))
    }

    @Test("explains a rate limit on login and sign-up instead of the generic message")
    func rateLimited() {
        let error = APIError.rateLimited(retryAfter: 600)

        #expect(AuthErrorMapper.loginMessage(for: error) == error.errorDescription)
        #expect(AuthErrorMapper.signUpMessage(for: error) == error.errorDescription)
    }

    @Test("falls back to generic message for unknown status codes")
    func genericFallback() {
        let message = AuthErrorMapper.loginMessage(for: .httpStatus(500, message: nil))
        #expect(message == L10n.string("login.submitError.generic"))
    }
}
