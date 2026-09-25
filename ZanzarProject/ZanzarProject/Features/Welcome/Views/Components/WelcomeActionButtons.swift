import SwiftUI

struct WelcomeActionButtons: View {
    let onCreateAccount: () -> Void
    let onLogin: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Button("welcome.createAccountButton.title", action: onCreateAccount)
                .buttonStyle(WelcomePrimaryButtonStyle())

            Button("welcome.loginButton.title", action: onLogin)
                .buttonStyle(WelcomeSecondaryButtonStyle())
        }
    }
}

private struct WelcomePrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body)
            .bold()
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color("WelcomePrimary"), in: .capsule)
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

private struct WelcomeSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body)
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color("WelcomeSecondaryBackground"), in: .capsule)
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

#Preview {
    WelcomeActionButtons(onCreateAccount: {}, onLogin: {})
        .padding()
}
