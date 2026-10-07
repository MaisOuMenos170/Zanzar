import SwiftUI

struct MainTabView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @State private var selectedTab: MainTab = .discover
    /// The profile tab pushes place details on its own path, separate from Discover's.
    @State private var profileCoordinator = AppCoordinator()

    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(MainTab.allCases, id: \.self) { tab in
                Tab(tab.titleKey, systemImage: tab.systemImage, value: tab) {
                    // tab bar's cascades into everything inside the tabs
                    // we overwrite with a .tint on the content inside
                    tabContent(for: tab)
                        .tint(.primary)
                }
            }
        }
        .tint(.tabBarSelected)
    }

    @ViewBuilder
    private func tabContent(for tab: MainTab) -> some View {
        switch tab {
        case .discover:
            NavigationStack(path: Bindable(coordinator).path) {
                LocationMapView()
                    .navigationDestination(for: Route.self) { coordinator.view(for: $0) }
            }
        case .checkIn:
            TabPlaceholderView(tab: tab)
        case .profile:
            NavigationStack(path: Bindable(profileCoordinator).path) {
                ProfileView()
                    .environment(profileCoordinator)
                    .navigationDestination(for: Route.self) { route in
                        profileCoordinator.view(for: route)
                            .environment(profileCoordinator)
                    }
            }
        }
    }
}

#Preview {
    MainTabView()
        .environment(AppCoordinator())
        .environment(AuthSession())
}
