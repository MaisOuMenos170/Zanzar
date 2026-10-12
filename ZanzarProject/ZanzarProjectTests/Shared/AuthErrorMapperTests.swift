import Foundation
import Testing
@testable import ZanzarProject

@Suite("AuthErrorMapper")
struct AuthErrorMapperTests {
    @Test("maps login 401 to invalid credentials")
    func loginUnauthorized() {
        let message = AuthErrorMapper.loginMessage(for: .httpStatus(401, message: "bad"))
        #expect(message == String(localized: "login.submitError.invalidCredentials"))
    }

    @Test("maps sign-up 409 to email in use")
    func signUpConflict() {
        let message = AuthErrorMapper.signUpMessage(for: .httpStatus(409, message: "exists"))
        #expect(message == String(localized: "signUp.submitError.emailInUse"))
    }

    @Test("falls back to generic message for unknown status codes")
    func genericFallback() {
        let message = AuthErrorMapper.loginMessage(for: .httpStatus(500, message: nil))
        #expect(message == String(localized: "login.submitError.generic"))
    }
}
