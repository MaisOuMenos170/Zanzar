import SwiftUI

struct ContentView: View {
    @State private var coordinator = AppCoordinator()

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            WelcomeView()
                .navigationDestination(for: Route.self) { coordinator.view(for: $0) }
        }
        .sheet(item: $coordinator.presentedSheet) { coordinator.view(for: $0) }
        .fullScreenCover(item: $coordinator.presentedFullScreenCover) { coordinator.view(for: $0) }
        .environment(coordinator)
    }
}

#Preview {
    ContentView()
}
