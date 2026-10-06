import SwiftUI

struct MainTabView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @State private var selectedTab: MainTab = .discover

    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(MainTab.allCases, id: \.self) { tab in
                Tab(tab.titleKey, systemImage: tab.systemImage, value: tab) {
                    tabContent(for: tab)
                }
            }
        }
        .tint(Color("TabBarSelected"))
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
            NavigationStack {
                ProfileView()
            }
            .tint(.primary)
        }
    }
}

#Preview {
    MainTabView()
        .environment(AppCoordinator())
        .environment(AuthSession())
}
