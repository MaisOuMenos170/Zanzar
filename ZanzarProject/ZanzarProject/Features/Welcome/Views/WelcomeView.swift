import SwiftUI

struct WelcomeView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var introDone = false

    var body: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 0)

            VStack(spacing: 16) {
                Button("welcome.createPassportButton.title") {
                    coordinator.push(.signUp)
                }
                .buttonStyle(AuthPrimaryButtonStyle(background: .brandOrange600))

                AuthSwitchLink(
                    promptKey: "auth.switch.haveAccount.prompt",
                    actionKey: "auth.switch.haveAccount.action"
                ) {
                    coordinator.push(.login)
                }
            }
            .opacity(introDone ? 1 : 0)
            .offset(y: introDone ? 0 : 24)
            .allowsHitTesting(introDone)
            .motion(Motion.chegada, value: introDone)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .background {
            ZStack {
                background
                WelcomeIllustrationView()
            }
            .ignoresSafeArea()
        }
        .task {
            guard !introDone else { return }
            // Figma: the buttons arrive 3.95 s in, once the character has landed. With Reduce Motion there is
            // nothing to wait for.
            if !reduceMotion {
                try? await Task.sleep(for: .seconds(3.95))
            }
            introDone = true
        }
    }

    private var background: some View {
        ZStack {
            Color(red: 0.947, green: 0.952, blue: 1)
            LinearGradient(
                stops: [
                    .init(color: Color(red: 0.63, green: 0.64, blue: 1), location: 0.05),
                    .init(color: .white, location: 1)
                ],
                startPoint: UnitPoint(x: 0.947, y: -0.134),
                endPoint: UnitPoint(x: 0.001, y: 1)
            )
            .opacity(0.2)
        }
    }
}

#Preview {
    WelcomeView()
        .environment(AppCoordinator())
}
