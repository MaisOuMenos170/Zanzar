import Foundation

nonisolated enum AuthErrorMapper {
    static func loginMessage(for error: APIError) -> String {
        mappedMessage(
            for: error,
            genericKey: "login.submitError.generic",
            statusMessages: [
                // The backend rejects a malformed password with 400 before it checks it. Such a password cannot
                // belong to any account, so it reads the same as a wrong one.
                400: "login.submitError.invalidCredentials",
                401: "login.submitError.invalidCredentials"
            ]
        )
    }

    static func appleLoginMessage(for error: APIError) -> String {
        mappedMessage(
            for: error,
            genericKey: "login.apple.error.generic",
            statusMessages: [
                400: "login.apple.error.missingEmail",
                401: "login.apple.error.invalidToken",
                403: "login.apple.error.signupDisabled",
                409: "login.apple.error.emailInUse"
            ]
        )
    }

    static func signUpMessage(for error: APIError) -> String {
        mappedMessage(
            for: error,
            genericKey: "signUp.submitError.generic",
            statusMessages: [
                409: "signUp.submitError.emailInUse"
            ]
        )
    }

    static func forgotPasswordMessage(for error: APIError) -> String {
        mappedMessage(for: error, genericKey: "passwordReset.forgot.error.generic", statusMessages: [:])
    }

    static func resetCodeMessage(for error: APIError) -> String {
        mappedMessage(
            for: error,
            genericKey: "passwordReset.code.error.generic",
            statusMessages: [
                400: "passwordReset.code.error.invalidOrExpired"
            ]
        )
    }

    static func newPasswordMessage(for error: APIError) -> String {
        mappedMessage(
            for: error,
            genericKey: "passwordReset.newPassword.error.generic",
            statusMessages: [
                401: "passwordReset.newPassword.error.expired"
            ]
        )
    }

    private static func mappedMessage(
        for error: APIError,
        genericKey: String,
        statusMessages: [Int: String]
    ) -> String {
        switch error {
        case .httpStatus(let statusCode, _), .rejected(let statusCode, _, _):
            if let localizedKey = statusMessages[statusCode] {
                return L10n.string(localizedKey)
            }
            // The server's own text is for logs, never for the screen: it is untranslated and can be a schema dump.
            return L10n.string(genericKey)
        case .rateLimited:
            return error.errorDescription ?? L10n.string(genericKey)
        case .decodingFailed, .invalidResponse, .invalidRequest:
            return L10n.string(genericKey)
        }
    }
}
