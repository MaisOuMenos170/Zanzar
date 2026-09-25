import SwiftUI

struct MainTabView: View {
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
            LocationMapView()
        case .checkIn, .profile:
            TabPlaceholderView(tab: tab)
        }
    }
}

#Preview {
    MainTabView()
        .environment(AppCoordinator())
}
