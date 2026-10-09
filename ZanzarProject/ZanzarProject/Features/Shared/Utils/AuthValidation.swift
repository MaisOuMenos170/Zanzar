import Foundation

nonisolated enum AuthValidation {
    static let minimumUsernameLength = 3
    static let minimumPasswordLength = 8
    private static var passwordPattern: Regex<Substring> { /^(?=.*[A-Za-z])(?=.*\d).{8,}$/ }

    static func emailError(
        for email: String,
        emptyKey: String,
        invalidKey: String
    ) -> String? {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            return emptyKey
        }

        if !isValidEmail(trimmed) {
            return invalidKey
        }

        return nil
    }

    static func usernameError(
        for username: String,
        emptyKey: String,
        tooShortKey: String
    ) -> String? {
        let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            return emptyKey
        }

        if trimmed.count < minimumUsernameLength {
            return tooShortKey
        }

        return nil
    }

    static func passwordError(
        for password: String,
        emptyKey: String,
        tooShortKey: String,
        invalidKey: String
    ) -> String? {
        if password.isEmpty {
            return emptyKey
        }

        if password.count < minimumPasswordLength {
            return tooShortKey
        }

        if password.wholeMatch(of: passwordPattern) == nil {
            return invalidKey
        }

        return nil
    }

    static func isValidEmail(_ email: String) -> Bool {
        let parts = email.split(separator: "@", maxSplits: 1, omittingEmptySubsequences: false)
        guard parts.count == 2,
              !parts[0].isEmpty,
              parts[1].contains(".") else {
            return false
        }
        return true
    }
}
