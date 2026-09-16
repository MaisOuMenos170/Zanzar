import SwiftUI

struct ContentView: View {
    @State private var coordinator = AppCoordinator()

    var body: some View {
        @Bindable var coordinator = coordinator

        NavigationStack(path: $coordinator.path) {
            LocationMarkView()
        }
        .navigationDestination(for: Route.self) { coordinator.view(for: $0) }
        .environment(coordinator)
    }
}

#Preview {
    ContentView()
}
