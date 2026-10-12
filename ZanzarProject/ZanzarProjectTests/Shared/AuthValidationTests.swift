import Foundation
import Testing
@testable import ZanzarProject

@Suite("AuthValidation")
struct AuthValidationTests {
    @Test(arguments: [
        ("", "empty"),
        ("not-an-email", "invalid"),
        ("user@domain.com", nil)
    ] as [(String, String?)])
    func emailValidation(email: String, expectedKey: String?) {
        let result = AuthValidation.emailError(
            for: email,
            emptyKey: "empty",
            invalidKey: "invalid"
        )
        #expect(result == expectedKey)
    }

    @Test(arguments: [
        ("", "empty"),
        ("ab", "short"),
        ("ana", nil)
    ] as [(String, String?)])
    func usernameValidation(username: String, expectedKey: String?) {
        let result = AuthValidation.usernameError(
            for: username,
            emptyKey: "empty",
            tooShortKey: "short"
        )
        #expect(result == expectedKey)
    }

    @Test(arguments: [
        ("", "empty"),
        ("1234567", "short"),
        ("abcdefgh", "invalid"),
        ("secret12", nil)
    ] as [(String, String?)])
    func passwordValidation(password: String, expectedKey: String?) {
        let result = AuthValidation.passwordError(
            for: password,
            emptyKey: "empty",
            tooShortKey: "short",
            invalidKey: "invalid"
        )
        #expect(result == expectedKey)
    }
}
