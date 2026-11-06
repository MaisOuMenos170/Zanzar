import SwiftUI

/// "Continuar com Apple": the Apple logo and label in the same type size as the other auth buttons. It only starts
/// the flow; the caller runs the Sign in with Apple request (see `LoginViewModel.signInWithApple`).
struct AuthAppleButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: "apple.logo")
                    .accessibilityHidden(true)
                Text("auth.apple.button.title")
            }
        }
        .buttonStyle(AuthPrimaryButtonStyle(background: .brandNeutral950))
    }
}

#Preview {
    AuthAppleButton {}
        .padding()
        .background(Color.brandBlue50)
}
