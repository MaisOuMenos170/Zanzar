import SwiftUI

struct ContentView: View {
    @State private var coordinator = AppCoordinator()
    @State private var authSession = AuthSession()
    @State private var toastPresenter = ToastPresenter()
    @State private var showsSessionExpiredAlert = false

    var body: some View {
        Group {
            if authSession.isAuthenticated {
                MainTabView()
            } else {
                NavigationStack(path: $coordinator.path) {
                    WelcomeView()
                        .navigationDestination(for: Route.self) { coordinator.view(for: $0) }
                }
            }
        }
        .onChange(of: authSession.isAuthenticated) {
            coordinator.popToRoot()
        }
        .sheet(item: $coordinator.presentedSheet) { coordinator.view(for: $0) }
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
