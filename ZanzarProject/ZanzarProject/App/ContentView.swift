import SwiftUI

struct ContentView: View {
    @State private var coordinator = AppCoordinator()
    @State private var authSession = AuthSession()
    @State private var toastPresenter = ToastPresenter()

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
        .fullScreenCover(item: $coordinator.presentedFullScreenCover) { coordinator.view(for: $0) }
        .safeAreaInset(edge: .top, spacing: 0) {
            ToastOverlay()
        }
        .environment(coordinator)
        .environment(authSession)
        .environment(toastPresenter)
    }
}

#Preview {
    ContentView()
}
