import AuthenticationServices
import Foundation
import Observation

@Observable
final class LoginViewModel {
    private let service: LoginServicing

    /// Raw nonce of the Apple request in flight; single use, cleared as soon as it is sent.
    @ObservationIgnored private var appleNonce: AppleSignInNonce?

    var email = ""
    var password = ""

    var emailError: String?
    var passwordError: String?
    var isLoading = false
    var submitError: String?

    init(service: LoginServicing = LoginService()) {
        self.service = service
    }

    @discardableResult
    func validateFields() -> Bool {
        emailError = AuthValidation.emailError(
            for: email,
            emptyKey: "login.emailField.errorEmpty",
            invalidKey: "login.emailField.errorInvalid"
        )
        passwordError = password.isEmpty
            ? "login.passwordField.errorEmpty"
            : nil

        return emailError == nil && passwordError == nil
    }

    /// Updates only the errors already on screen, so a field clears as soon as its value becomes valid.
    func refreshShownFieldErrors() {
        if emailError != nil {
            emailError = AuthValidation.emailError(
                for: email,
                emptyKey: "login.emailField.errorEmpty",
                invalidKey: "login.emailField.errorInvalid"
            )
        }
        if passwordError != nil {
            passwordError = password.isEmpty ? "login.passwordField.errorEmpty" : nil
        }
    }

    func submit(using authSession: AuthSession) async -> Bool {
        guard !isLoading else { return false }

        submitError = nil
        guard validateFields() else { return false }

        isLoading = true
        defer { isLoading = false }

        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            let response = try await service.submitLogin(
                LoginRequest(email: trimmedEmail, password: password)
            )
            try authSession.signIn(accessToken: response.token, refreshToken: response.refreshToken)
            return true
        } catch let error as APIError {
            submitError = AuthErrorMapper.loginMessage(for: error)
            return false
        } catch {
            submitError = String(localized: "login.submitError.generic")
            return false
        }
    }

    // MARK: - Sign in with Apple

    /// Asks Apple for the name and email (delivered only on the first authorization) and binds the request to a fresh nonce.
    func configureAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = AppleSignInNonce.random()
        appleNonce = nonce
        submitError = nil
        request.requestedScopes = [.fullName, .email]
        request.nonce = nonce.hashed
    }

    func completeAppleSignIn(_ result: Result<ASAuthorization, Error>, using authSession: AuthSession) async -> Bool {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                submitError = String(localized: "login.apple.error.generic")
                return false
            }
            return await submitApple(
                identityToken: credential.identityToken,
                fullName: credential.fullName,
                using: authSession
            )
        case .failure(let error):
            // Dismissing the Apple sheet is not an error worth showing.
            if (error as? ASAuthorizationError)?.code == .canceled {
                return false
            }
            AppLog.login.error("Apple authorization failed", error: error)
            submitError = String(localized: "login.apple.error.generic")
            return false
        }
    }

    func submitApple(
        identityToken: Data?,
        fullName: PersonNameComponents?,
        using authSession: AuthSession
    ) async -> Bool {
        guard !isLoading else { return false }

        submitError = nil
        let nonce = appleNonce
        appleNonce = nil

        guard let nonce,
              let identityToken,
              let token = String(data: identityToken, encoding: .utf8),
              !token.isEmpty
        else {
            submitError = String(localized: "login.apple.error.generic")
            return false
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await service.submitAppleLogin(
                AppleLoginRequest(
                    identityToken: token,
                    nonce: nonce.raw,
                    fullName: Self.appleFullName(from: fullName)
                )
            )
            try authSession.signIn(accessToken: response.token, refreshToken: response.refreshToken)
            return true
        } catch let error as APIError {
            submitError = AuthErrorMapper.appleLoginMessage(for: error)
            return false
        } catch {
            submitError = String(localized: "login.apple.error.generic")
            return false
        }
    }

    private static func appleFullName(from components: PersonNameComponents?) -> AppleLoginRequest.FullName? {
        let givenName = components?.givenName?.trimmingCharacters(in: .whitespacesAndNewlines)
        let familyName = components?.familyName?.trimmingCharacters(in: .whitespacesAndNewlines)
        let given = givenName?.isEmpty == false ? givenName : nil
        let family = familyName?.isEmpty == false ? familyName : nil
        guard given != nil || family != nil else { return nil }
        return AppleLoginRequest.FullName(givenName: given, familyName: family)
    }
}
