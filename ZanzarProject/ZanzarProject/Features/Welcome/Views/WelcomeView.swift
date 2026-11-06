import SwiftUI

/// First screen for a signed-out user: the way in ("Criar meu passaporte") or back to an existing account.
/// The passport only appears after the avatar is saved.
struct WelcomeView: View {
    @Environment(AppCoordinator.self) private var coordinator

    var body: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 0)

            VStack(spacing: 16) {
                Button("welcome.createPassportButton.title") {
                    coordinator.push(.signUp)
                }
                .buttonStyle(AuthPrimaryButtonStyle())

                AuthSwitchLink(
                    promptKey: "auth.switch.haveAccount.prompt",
                    actionKey: "auth.switch.haveAccount.action"
                ) {
                    coordinator.push(.login)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .background(Color.brandBlue50.ignoresSafeArea())
    }
}

#Preview {
    WelcomeView()
        .environment(AppCoordinator())
}
