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
    /// A tap on a proximity alert waits here, possibly from before this screen existed.
    private let alertRouter = ProximityAlertRouter.shared
    /// Tells the proximity alerts which roteiro the user is following; the server is the source of truth.
    @State private var itineraryFeed = ActiveItineraryFeed(
        service: ItineraryService(),
        apply: { active in
            await ProximityAlertCoordinator.shared.update(itinerary: active)
            WidgetDataWriter.shared.update(itinerary: active)
        }
    )
    /// Explains and asks for the permissions behind the proximity alerts, at a moment that makes sense.
    @State private var proximityPermission = ProximityPermissionViewModel(
        service: SystemProximityPermissionService(),
        store: UserDefaultsProximityAlertStore(),
        onPermissionsChanged: { await ProximityAlertCoordinator.shared.refresh() }
    )
    /// Held until the sheet is fully dismissed so the alert is not lost mid-dismissal.
    @State private var pendingSuggestionOutcome: PlaceSuggestionOutcome?
    @State private var shownSuggestionOutcome: PlaceSuggestionOutcome?
    @State private var showsSuggestionAlert = false
    @State private var photoStatusNotice = PhotoStatusNoticeViewModel()
    @State private var suggestionStatusNotice = SuggestionStatusNoticeViewModel()
    @Environment(ToastManager.self) private var toastManager
    @Environment(\.scenePhase) private var scenePhase
    @Namespace private var placeZoom

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
        // The system tab bar, with the app's new blue (Blue/600 in the Figma) for the selected tab.
        .tint(.brandBlue600)
        // Presented here, not by ContentView, so the sheet sees the shared places and can open a place
        // on the check-in tab's path once it closes.
        .sheet(item: itinerarySheet, onDismiss: presentPendingSuggestionAlert) { sheet in
            coordinator.view(
                for: sheet,
                onSelectPlace: { place in
                    coordinator.dismissSheet()
                    checkInCoordinator.push(.placeDetail(place))
                },
                onPlaceSuggestionFinished: finishSuggestion
            )
        }
        // "Sugerir um lugar" is a full-width card of its own (see `PlaceSuggestionSheetCard`), not a system sheet.
        .overlay {
            if coordinator.presentedSheet == .suggestPlace {
                coordinator.view(
                    for: .suggestPlace,
                    onSelectPlace: { _ in },
                    onPlaceSuggestionFinished: finishSuggestion
                )
            }
        }
        .motion(Motion.assentar, value: coordinator.presentedSheet)
        .onChange(of: coordinator.presentedSheet) { previous, current in
            guard previous == .suggestPlace, current == nil else { return }
            // An alert cannot appear while the card is still leaving.
            Task {
                try? await Task.sleep(for: .milliseconds(400))
                presentPendingSuggestionAlert()
            }
        }
        .placeSuggestionOutcomeAlert(isPresented: $showsSuggestionAlert, outcome: shownSuggestionOutcome)
        .environment(nearbyPlaces)
        .overlay {
            if proximityPermission.isVisible {
                ProximityPermissionPromptView(viewModel: proximityPermission)
            }
        }
        .onAppear {
            itineraryFeed.refresh()
            openTappedAlertPlace()
        }
        .onChange(of: alertRouter.pendingPlaceID) {
            openTappedAlertPlace()
        }
        // Starting, abandoning or advancing a roteiro changes the next stop that gets watched.
        .onReceive(NotificationCenter.default.publisher(for: AppNotification.activeItineraryDidChange)) { _ in
            itineraryFeed.refresh()
        }
        .onReceive(NotificationCenter.default.publisher(for: AppNotification.checkInDidSucceed)) { _ in
            itineraryFeed.refresh()
            Task { await proximityPermission.momentOccurred(.firstCheckIn) }
        }
        .onReceive(NotificationCenter.default.publisher(for: AppNotification.itineraryDidStart)) { _ in
            Task { await proximityPermission.momentOccurred(.itineraryStarted) }
        }
        // The user may have changed the permissions in Settings while the app was in the background.
        .onChange(of: scenePhase) {
            guard scenePhase == .active else { return }
            itineraryFeed.refresh()
            Task { await ProximityAlertCoordinator.shared.refresh() }
        }
        // Pins and the carousel read the shared places; coming back to a tab refetches them only if stale.
        // Tells the user when a review of one of their photos finished, each time the app comes to the front.
        .task(id: scenePhase) {
            guard scenePhase == .active else { return }
            if let message = await photoStatusNotice.checkForChanges() {
                toastManager.show(message, style: .positive)
            }
            if let message = await suggestionStatusNotice.checkForChanges() {
                toastManager.show(message, style: .positive)
            }
        }
        // The regions watched for proximity alerts follow the places around the user.
        .onChange(of: nearbyPlaces.lastFetchedAt) {
            let places = nearbyPlaces.places
            let user = nearbyPlaces.userCoordinate
            Task { await ProximityAlertCoordinator.shared.update(places: places, user: user) }
            // The widget names the next stop from the same places.
            WidgetDataWriter.shared.update(places: places)
        }
        .onChange(of: selectedTab) { _, tab in
            guard tab != .profile else { return }
            Task { try? await nearbyPlaces.refreshIfNeeded() }
        }
    }

    /// The system sheet only carries the roteiro detail; the suggestion form is drawn by the overlay.
    private var itinerarySheet: Binding<Sheet?> {
        Binding(
            get: {
                guard case .itineraryDetail = coordinator.presentedSheet else { return nil }
                return coordinator.presentedSheet
            },
            set: { if $0 == nil, case .itineraryDetail = coordinator.presentedSheet { coordinator.dismissSheet() } }
        )
    }

    private func finishSuggestion(_ outcome: PlaceSuggestionOutcome) {
        pendingSuggestionOutcome = outcome
        coordinator.dismissSheet()
    }

    /// The user tapped a proximity alert: show that place on Discover, whatever they were looking at.
    private func openTappedAlertPlace() {
        guard let placeID = alertRouter.consume() else { return }
        let place = ProximityAlertRouter.place(
            for: placeID,
            loaded: nearbyPlaces.places,
            saved: UserDefaultsProximityAlertStore().loadMonitoredPlaces()
        )
        guard let place else { return }
        coordinator.dismissSheet()
        coordinator.popToRoot()
        selectedTab = .discover
        coordinator.push(.placeDetail(place))
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
                LocationMapView(store: nearbyPlaces, zoomNamespace: placeZoom)
                    .navigationDestination(for: Route.self) { route in
                        if case .placeDetail(let place, true) = route {
                            coordinator.view(for: route)
                                .navigationTransition(.zoom(sourceID: place.id, in: placeZoom))
                        } else {
                            coordinator.view(for: route)
                        }
                    }
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
