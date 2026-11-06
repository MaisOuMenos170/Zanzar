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
    /// Held until the sheet is fully dismissed so the alert is not lost mid-dismissal.
    @State private var pendingSuggestionOutcome: PlaceSuggestionOutcome?
    @State private var shownSuggestionOutcome: PlaceSuggestionOutcome?
    @State private var showsSuggestionAlert = false
    @State private var photoStatusNotice = PhotoStatusNoticeViewModel()
    @Environment(ToastPresenter.self) private var toastPresenter
    @Environment(\.scenePhase) private var scenePhase

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
        // Presented here, not by ContentView, so the sheet sees the shared places and can open a place
        // on the check-in tab's path once it closes.
        .sheet(item: Bindable(coordinator).presentedSheet, onDismiss: presentPendingSuggestionAlert) { sheet in
            coordinator.view(
                for: sheet,
                onSelectPlace: { place in
                    coordinator.dismissSheet()
                    checkInCoordinator.push(.placeDetail(place))
                },
                onPlaceSuggestionFinished: { outcome in
                    pendingSuggestionOutcome = outcome
                    coordinator.dismissSheet()
                }
            )
        }
        .placeSuggestionOutcomeAlert(isPresented: $showsSuggestionAlert, outcome: shownSuggestionOutcome)
        .environment(nearbyPlaces)
        // Pins and the carousel read the shared places; coming back to a tab refetches them only if stale.
        // Tells the user when a review of one of their photos finished, each time the app comes to the front.
        .task(id: scenePhase) {
            guard scenePhase == .active, let message = await photoStatusNotice.checkForChanges() else { return }
            toastPresenter.show(message)
        }
        .onChange(of: selectedTab) { _, tab in
            guard tab != .profile else { return }
            Task { try? await nearbyPlaces.refreshIfNeeded() }
        }
    }

    private func presentPendingSuggestionAlert() {
        guard let outcome = pendingSuggestionOutcome else { return }
        pendingSuggestionOutcome = nil
        shownSuggestionOutcome = outcome
        showsSuggestionAlert = true
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
