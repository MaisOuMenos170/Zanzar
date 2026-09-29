import SwiftUI

struct ContentView: View {
    @State private var coordinator = AppCoordinator()
    @State private var authSession = AuthSession()

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            Group {
                if authSession.isAuthenticated {
                    MainTabView()
                } else {
                    WelcomeView()
                }
            }
            .navigationDestination(for: Route.self) { coordinator.view(for: $0) }
        }
        .sheet(item: $coordinator.presentedSheet) { coordinator.view(for: $0) }
        .fullScreenCover(item: $coordinator.presentedFullScreenCover) { coordinator.view(for: $0) }
        .environment(coordinator)
        .environment(authSession)
        .task {
            authSession.restore()
        }
    }
}

#Preview {
    ContentView()
}
