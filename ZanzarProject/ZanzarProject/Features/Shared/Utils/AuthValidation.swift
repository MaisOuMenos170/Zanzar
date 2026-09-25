import Foundation

enum AuthValidation {
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
