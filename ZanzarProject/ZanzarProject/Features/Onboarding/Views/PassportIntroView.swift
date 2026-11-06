import SwiftUI

/// Shown once after the avatar is saved: "Começar" stamps the passport and then enters the app.
struct PassportIntroView: View {
    @State private var viewModel: PassportIntroViewModel
    @State private var isStamping = false
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(OnboardingGate.self) private var onboarding

    init(avatar: Avatar, username: String?) {
        _viewModel = State(initialValue: PassportIntroViewModel(avatar: avatar, name: username))
    }

    var body: some View {
        VStack(spacing: 16) {
            PassportStampAnimationView(
                avatar: viewModel.avatar,
                name: viewModel.name,
                isPlaying: isStamping,
                onFinished: enterApp
            )

            Button("passport.startButton.title") {
                isStamping = true
            }
            .buttonStyle(AuthPrimaryButtonStyle())
            .disabled(isStamping)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .background(Color.brandBlue50.ignoresSafeArea())
        .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
        .task {
            await viewModel.loadNameIfNeeded()
        }
    }

    /// Finishing the gate swaps in the main tabs; the auth stack is reset for the next sign-out.
    private func enterApp() {
        onboarding.finish()
        coordinator.popToRoot()
    }
}

#Preview {
    NavigationStack {
        PassportIntroView(avatar: .placeholder, username: "Maria")
            .environment(AppCoordinator())
            .environment(OnboardingGate())
    }
}
