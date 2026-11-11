import Foundation

protocol PasswordResetServicing: Sendable {
    /// `POST /password/forgot`. Always succeeds (202) whether or not the email has an account.
    func requestCode(email: String) async throws
    /// `POST /password/verify`. Consumes the code or the link token and returns a reset token (10 minutes, single use).
    func verify(_ request: VerifyResetRequest) async throws -> String
    /// `POST /password/reset`. The backend revokes every session of the user.
    func resetPassword(resetToken: String, newPassword: String) async throws
}

nonisolated struct ForgotPasswordRequest: Encodable, Sendable {
    let email: String
}

/// Body of `POST /password/verify`: the 6-digit code with its email, or the token of the email link. Never both.
nonisolated enum VerifyResetRequest: Encodable, Sendable, Equatable {
    case code(email: String, code: String)
    case link(token: String)

    private enum CodingKeys: String, CodingKey {
        case email
        case code
        case token
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .code(let email, let code):
            try container.encode(email, forKey: .email)
            try container.encode(code, forKey: .code)
        case .link(let token):
            try container.encode(token, forKey: .token)
        }
    }
}

nonisolated struct ResetTokenResponse: Decodable, Sendable {
    let resetToken: String
}

nonisolated struct ResetPasswordRequest: Encodable, Sendable {
    let resetToken: String
    let newPassword: String
}

final class PasswordResetService: PasswordResetServicing {
    private let client: NetworkClient

    init(client: NetworkClient = URLSessionNetworkClient.shared) {
        self.client = client
    }

    func requestCode(email: String) async throws {
        AppLog.passwordReset.info("Requesting a reset code...")
        do {
            try await client.sendWithoutResponse(
                path: "password/forgot",
                method: .post,
                body: ForgotPasswordRequest(email: email)
            )
            AppLog.passwordReset.info("Reset code requested")
        } catch {
            AppLog.passwordReset.error("Reset code request failed", error: error)
            throw error
        }
    }

    func verify(_ request: VerifyResetRequest) async throws -> String {
        let source = switch request {
        case .code: "code"
        case .link: "link"
        }
        AppLog.passwordReset.info("Verifying the reset \(source)...")
        do {
            let response: ResetTokenResponse = try await client.send(
                path: "password/verify",
                method: .post,
                body: request
            )
            AppLog.passwordReset.info("Reset \(source) verified")
            return response.resetToken
        } catch {
            AppLog.passwordReset.error("Reset \(source) verification failed", error: error)
            throw error
        }
    }

    func resetPassword(resetToken: String, newPassword: String) async throws {
        AppLog.passwordReset.info("Saving the new password...")
        do {
            try await client.sendWithoutResponse(
                path: "password/reset",
                method: .post,
                body: ResetPasswordRequest(resetToken: resetToken, newPassword: newPassword)
            )
            AppLog.passwordReset.info("New password saved")
        } catch {
            AppLog.passwordReset.error("Saving the new password failed", error: error)
            throw error
        }
    }
}
