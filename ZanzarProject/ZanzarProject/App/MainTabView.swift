import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: MainTab = .discover

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("mainTab.discoverTab.title", systemImage: "map", value: .discover) {
                LocationMapView()
            }

            Tab("mainTab.checkInTab.title", systemImage: "mappin", value: .checkIn) {
                TabPlaceholderView(tab: .checkIn)
            }

            Tab("mainTab.profileTab.title", systemImage: "person", value: .profile) {
                TabPlaceholderView(tab: .profile)
            }
        }
        .tint(Color("TabBarSelected"))
    }
}

#Preview {
    MainTabView()
        .environment(AppCoordinator())
}
