import SwiftUI

struct ContentView: View {
    @State private var coordinator = AppCoordinator()
    @State private var authSession = AuthSession()
    @State private var toastPresenter = ToastPresenter()
    @State private var onboarding = OnboardingGate()
    @State private var showsSessionExpiredAlert = false

    var body: some View {
        Group {
            if authSession.isAuthenticated && !onboarding.isActive {
                MainTabView()
            } else {
                NavigationStack(path: $coordinator.path) {
                    WelcomeView()
                        .navigationDestination(for: Route.self) { coordinator.view(for: $0) }
                }
            }
        }
        .onChange(of: authSession.isAuthenticated) {
            // While onboarding the coordinator already points at the avatar editor.
            guard !onboarding.isActive else { return }
            coordinator.popToRoot()
        }
        .alert("auth.sessionExpired.title", isPresented: $showsSessionExpiredAlert) {
            Button("auth.sessionExpired.dismissButton.title", role: .cancel) {}
        } message: {
            Text("auth.sessionExpired.message")
        }
        .onReceive(NotificationCenter.default.publisher(for: AppNotification.sessionExpired)) { _ in
            handleSessionExpired()
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            ToastOverlay()
        }
        .preferredColorScheme(.light)
        .environment(coordinator)
        .environment(authSession)
        .environment(toastPresenter)
        .environment(onboarding)
    }
}

private extension ContentView {
    func handleSessionExpired() {
        guard authSession.isAuthenticated else { return }
        authSession.handleSessionExpired()
        let hadSheet = coordinator.presentedSheet != nil
        coordinator.dismissSheet()
        coordinator.popToRoot()
        guard hadSheet else {
            showsSessionExpiredAlert = true
            return
        }
        // An alert can't appear while the sheet is still dismissing.
        Task {
            try? await Task.sleep(for: .milliseconds(500))
            showsSessionExpiredAlert = true
        }
    }
}

#Preview {
    ContentView()
}
