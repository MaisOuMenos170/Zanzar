import SwiftUI

/// Shown once after the avatar is saved: the user's passport gets its first stamp, then "Começar" enters the app.
struct PassportIntroView: View {
    @State private var viewModel: PassportIntroViewModel
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(OnboardingGate.self) private var onboarding

    init(avatar: Avatar, username: String?) {
        _viewModel = State(initialValue: PassportIntroViewModel(avatar: avatar, name: username))
    }

    var body: some View {
        VStack(spacing: 16) {
            PassportStampAnimationView(avatar: viewModel.avatar, name: viewModel.name)

            Button("passport.startButton.title") {
                // Finishing the gate swaps in the main tabs; the auth stack is reset for the next sign-out.
                onboarding.finish()
                coordinator.popToRoot()
            }
            .buttonStyle(AuthPrimaryButtonStyle())
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .background(Color.brandBlue50.ignoresSafeArea())
        .navigationBarBackButtonHidden()
        .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                BackButton {
                    coordinator.pop()
                }
            }
        }
        .task {
            await viewModel.loadNameIfNeeded()
        }
    }
}

#Preview {
    NavigationStack {
        PassportIntroView(avatar: .placeholder, username: "Maria")
            .environment(AppCoordinator())
            .environment(OnboardingGate())
    }
}
