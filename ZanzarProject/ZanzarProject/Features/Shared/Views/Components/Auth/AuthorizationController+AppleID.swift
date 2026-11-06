import AuthenticationServices
import SwiftUI

extension AuthorizationController {
    /// Shows the Sign in with Apple sheet for `request` and returns the credential the user approved.
    func appleIDCredential(
        for request: ASAuthorizationAppleIDRequest
    ) async throws -> ASAuthorizationAppleIDCredential {
        guard case .appleID(let credential) = try await performRequests([request]) else {
            throw ASAuthorizationError(.unknown)
        }
        return credential
    }
}
