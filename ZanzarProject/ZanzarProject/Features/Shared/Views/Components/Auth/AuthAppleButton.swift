import AuthenticationServices
import SwiftUI

/// System "Continuar com Apple" button styled as a full-width capsule. The caller wires the Apple request/result
/// handlers, so it works the same on the login and the sign-up screens.
struct AuthAppleButton: View {
    let onRequest: (ASAuthorizationAppleIDRequest) -> Void
    let onCompletion: (Result<ASAuthorization, Error>) -> Void

    var body: some View {
        SignInWithAppleButton(.continue, onRequest: onRequest, onCompletion: onCompletion)
            .signInWithAppleButtonStyle(.black)
            .frame(height: 52)
            .clipShape(.capsule)
    }
}
