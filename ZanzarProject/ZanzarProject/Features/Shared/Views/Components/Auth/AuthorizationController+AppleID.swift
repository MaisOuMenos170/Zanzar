import AuthenticationServices
import SwiftUI

extension AuthorizationController {
    func appleIDCredential(
        for request: ASAuthorizationAppleIDRequest
    ) async throws -> ASAuthorizationAppleIDCredential {
        guard case .appleID(let credential) = try await performRequests([request]) else {
            throw ASAuthorizationError(.unknown)
        }
        return credential
    }
}
