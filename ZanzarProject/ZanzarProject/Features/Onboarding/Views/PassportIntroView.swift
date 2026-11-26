import SwiftUI

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
        // The system back button is read as the previous screen's title ("Tom de pele", which changes with the
        // editor tab), so this one says "Voltar" itself.
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    coordinator.pop()
                } label: {
                    Label("backButton.accessibilityLabel", systemImage: "chevron.left")
                        .labelStyle(.iconOnly)
                }
            }
        }
        .task {
            await viewModel.loadNameIfNeeded()
        }
    }

    /// After the passport animation, ask for notifications before opening the app.
    private func enterApp() {
        coordinator.push(.notificationPermission)
    }
}

#Preview {
    NavigationStack {
        PassportIntroView(avatar: .placeholder, username: "Maria")
            .environment(AppCoordinator())
            .environment(OnboardingGate())
    }
}
