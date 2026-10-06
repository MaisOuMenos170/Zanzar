import Foundation

enum AuthErrorMapper {
    static func loginMessage(for error: APIError) -> String {
        mappedMessage(
            for: error,
            genericKey: "login.submitError.generic",
            statusMessages: [
                401: "login.submitError.invalidCredentials",
            ]
        )
    }

    static func signUpMessage(for error: APIError) -> String {
        mappedMessage(
            for: error,
            genericKey: "signUp.submitError.generic",
            statusMessages: [
                409: "signUp.submitError.emailInUse",
            ]
        )
    }

    private static func mappedMessage(
        for error: APIError,
        genericKey: String.LocalizationValue,
        statusMessages: [Int: String.LocalizationValue]
    ) -> String {
        switch error {
        case .httpStatus(let statusCode, let message):
            if let localizedKey = statusMessages[statusCode] {
                return String(localized: localizedKey)
            }
            #if DEBUG
            if let message, !message.isEmpty {
                return message
            }
            #endif
            return String(localized: genericKey)
        case .decodingFailed, .invalidResponse, .invalidRequest:
            return String(localized: genericKey)
        }
    }
}
