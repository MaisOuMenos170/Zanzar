import SwiftUI

struct WelcomeView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @State private var hasAppeared = false

    var body: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 0)

            VStack(spacing: 16) {
                Button("welcome.createPassportButton.title") {
                    coordinator.push(.signUp)
                }
                .buttonStyle(AuthPrimaryButtonStyle())
                .entrance(hasAppeared, order: 0)

                AuthSwitchLink(
                    promptKey: "auth.switch.haveAccount.prompt",
                    actionKey: "auth.switch.haveAccount.action"
                ) {
                    coordinator.push(.login)
                }
                .entrance(hasAppeared, order: 1)
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
