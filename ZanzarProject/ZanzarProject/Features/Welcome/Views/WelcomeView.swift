import SwiftUI
import TipKit

struct WelcomeView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @State private var hasAppeared = false

    private let createAccountTip = WelcomeCreateAccountTip()
    private let signInTip = WelcomeSignInTip()

    var body: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 0)

            VStack(spacing: 16) {
                Button("welcome.createPassportButton.title") {
                    coordinator.push(.signUp)
                    WelcomeCreateAccountTip.hasSeenWelcome = true
                }
                .buttonStyle(AuthPrimaryButtonStyle())
                .entrance(hasAppeared, order: 0)
                .popoverTip(createAccountTip, arrowEdge: .bottom)

                AuthSwitchLink(
                    promptKey: "auth.switch.haveAccount.prompt",
                    actionKey: "auth.switch.haveAccount.action"
                ) {
                    coordinator.push(.login)
                    WelcomeSignInTip.hasSeenWelcome = true
                }
                .entrance(hasAppeared, order: 1)
                .popoverTip(signInTip, arrowEdge: .bottom)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .background(Color.brandBlue50.ignoresSafeArea())
        .onAppear {
            hasAppeared = true
        }
    }
}

#Preview {
    WelcomeView()
        .environment(AppCoordinator())
}
