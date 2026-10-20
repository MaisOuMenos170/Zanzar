import SwiftUI

struct MainTabView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @State private var selectedTab: MainTab = .discover
    /// The profile tab pushes place details on its own path, separate from Discover's.
    @State private var profileCoordinator = AppCoordinator()
    /// The check-in tab keeps its own navigation path and uses the root coordinator for sheets.
    @State private var checkInCoordinator = AppCoordinator()
    /// The places around the user, shared by Discover, the check-in tab and every place detail.
    @State private var nearbyPlaces = NearbyPlacesStore()

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
        .environment(nearbyPlaces)
        // Pins and the carousel read the shared places; coming back to a tab refetches them only if stale.
        .onChange(of: selectedTab) { _, tab in
            guard tab != .profile else { return }
            Task { try? await nearbyPlaces.refreshIfNeeded() }
        }
    }

    @ViewBuilder
    private func tabContent(for tab: MainTab) -> some View {
        switch tab {
        case .discover:
            NavigationStack(path: Bindable(coordinator).path) {
                LocationMapView(store: nearbyPlaces)
                    .navigationDestination(for: Route.self) { coordinator.view(for: $0) }
            }
        case .checkIn:
            NavigationStack(path: Bindable(checkInCoordinator).path) {
                ItineraryListView(sheetCoordinator: coordinator)
                    .environment(checkInCoordinator)
                    .navigationDestination(for: Route.self) { route in
                        checkInCoordinator.view(for: route)
                            .environment(checkInCoordinator)
                            .tint(Color("TabBarSelected"))
                    }
            }
            .tint(.primary)
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
