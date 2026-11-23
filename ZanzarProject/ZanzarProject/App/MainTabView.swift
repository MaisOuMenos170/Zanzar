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
    @State private var suggestionGoodNewsCount = 0
    @State private var suggestionBadNewsCount = 0
    @State private var photoStatusNotice = PhotoStatusNoticeViewModel()
    @State private var suggestionStatusNotice = SuggestionStatusNoticeViewModel()
    /// Asks how the visit went once the user has left a place they checked in at, on whichever screen they are.
    @State private var ratingPrompt = RatingPromptViewModel()
    /// A check-in saves a pending rating, so the monitor that waits for the user to leave has to start again.
    @State private var checkInEvents = 0
    @Environment(ToastManager.self) private var toastManager
    @Environment(\.scenePhase) private var scenePhase
    @Namespace private var placeZoom

    var body: some View {
        TabView(selection: tabSelection) {
            ForEach(MainTab.screenTabs, id: \.self) { tab in
                Tab(tab.titleKey, systemImage: tab.systemImage, value: tab) {
                    // tab bar's cascades into everything inside the tabs
                    // we overwrite with a .tint on the content inside
                    tabContent(for: tab)
                        .tint(.primary)
                }
            }
            // The separate tab on the trailing side of the bar. It is an action, not a screen: see `tabSelection`.
            Tab(
                MainTab.suggest.titleKey,
                systemImage: MainTab.suggest.systemImage,
                value: MainTab.suggest,
                role: .search
            ) {
                Color.clear
            }
            // Only the Discover tab offers it.
            .hidden(selectedTab != .discover)
        }
        // The system tab bar, with the app's new blue (Blue/600 in the Figma) for the selected tab.
        .tint(.brandBlue600)
        // Presented here, not by ContentView, so the sheet sees the shared places and can open a place
        // on the check-in tab's path once it closes.
        .sheet(item: itinerarySheet) { sheet in
            coordinator.view(
                for: sheet,
                onSelectPlace: { place in
                    coordinator.dismissSheet()
                    checkInCoordinator.push(.placeDetail(place))
                },
                onPlaceSuggestionFinished: finishSuggestion
            )
        }
        // "Sugerir um lugar" and "Editar nome" are full-width cards of their own (see `PlaceSuggestionSheetCard`),
        // not system sheets.
        .overlay { cardHost }
        .haptic(.selecao, trigger: selectedTab)
        .haptic(.sucesso, trigger: suggestionGoodNewsCount)
        .haptic(.alerta, trigger: suggestionBadNewsCount)
        .environment(nearbyPlaces)
        .alert("ratingPrompt.success.title", isPresented: $ratingPrompt.showsSuccess) {
            Button("ratingPrompt.success.confirm") {}
        } message: {
            Text("ratingPrompt.success.message")
        }
        .task(id: ratingMonitorKey) {
            guard scenePhase == .active else { return }
            await ratingPrompt.monitorLeaving()
        }
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
            checkInEvents += 1
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

    /// Tapping the separate "Sugerir um lugar" tab opens the suggestion card and keeps the current tab selected,
    /// so the haptic and the places refresh keyed on `selectedTab` do not fire for it.
    private var tabSelection: Binding<MainTab> {
        Binding(
            get: { selectedTab },
            set: { tab in
                if tab == .suggest {
                    coordinator.present(sheet: .suggestPlace)
                } else {
                    selectedTab = tab
                }
            }
        )
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

    /// The container stays in the view tree while a card comes and goes, so the dimmer fades and the card slides
    /// for every way of closing it (the button, a tap outside, a drag, or the form finishing).
    private var cardHost: some View {
        ZStack(alignment: .bottom) {
            if let sheet = coordinator.presentedSheet, isCard(sheet) {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture { coordinator.dismissSheet() }
                    .accessibilityHidden(true)
                    .transition(.opacity)

                card(for: sheet)
                    .transition(SheetSlideTransition())
            }

            // The rating sheet is not dismissed by a tap outside: closing it drops the pending rating for good.
            if ratingPrompt.isPresented, let pendingRating = ratingPrompt.pendingRating {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .accessibilityHidden(true)
                    .transition(.opacity)

                RatingPromptView(
                    placeID: pendingRating.placeID,
                    placeName: pendingRating.placeName,
                    categoryTitleKey: pendingRating.categoryTitleKey,
                    selectedTag: ratingPrompt.selectedTag,
                    isSubmitting: ratingPrompt.isSubmitting,
                    errorMessage: ratingPrompt.errorMessage,
                    onSelect: { ratingPrompt.select($0) },
                    onSubmit: { Task { await ratingPrompt.submit() } },
                    onDismiss: { ratingPrompt.dismiss() }
                )
                .transition(SheetSlideTransition())
            }
        }
        .motion(Motion.cartao, value: coordinator.presentedSheet)
        .motion(Motion.cartao, value: ratingPrompt.isPresented)
    }

    /// Changes when the app comes to the foreground or a check-in is made, which is when to look again.
    private var ratingMonitorKey: Int {
        (scenePhase == .active ? 1 : 0) + checkInEvents * 2
    }

    private func isCard(_ sheet: Sheet) -> Bool {
        switch sheet {
        case .suggestPlace, .editName: true
        case .itineraryDetail: false
        }
    }

    @ViewBuilder
    private func card(for sheet: Sheet) -> some View {
        switch sheet {
        case .suggestPlace:
            coordinator.view(
                for: .suggestPlace,
                onSelectPlace: { _ in },
                onPlaceSuggestionFinished: finishSuggestion
            )
        case .editName(let currentName):
            PlaceSuggestionSheetCard(onClose: { coordinator.dismissSheet() }, content: {
                EditNameSheetView(
                    currentName: currentName,
                    onSaved: {
                        coordinator.dismissSheet()
                        NotificationCenter.default.post(name: AppNotification.profileNameDidChange, object: nil)
                    },
                    onClose: { coordinator.dismissSheet() }
                )
            })
        case .itineraryDetail:
            EmptyView()
        }
    }

    /// Closes the card and tells the user how the suggestion went, in a toast above the tab bar.
    private func finishSuggestion(_ outcome: PlaceSuggestionOutcome) {
        coordinator.dismissSheet()
        toastManager.show(outcome.toastMessage, style: outcome.toastStyle, position: .bottom)
        if outcome.isGoodNews {
            suggestionGoodNewsCount += 1
        } else {
            suggestionBadNewsCount += 1
        }
    }

    /// The user tapped a proximity alert: show that place on Discover, whatever they were looking at.
    private func openTappedAlertPlace() {
        guard let placeID = alertRouter.consume() else { return }
        let place = ProximityAlertRouter.place(
            for: placeID,
            loaded: nearbyPlaces.places,
            saved: UserDefaultsProximityAlertStore().loadMonitoredPlaces()
        )
        if let place {
            open(place)
            return
        }
        // A shared link can name a place the app has not loaded.
        Task {
            do {
                open(try await PlaceLinkService().place(id: placeID))
            } catch {
                AppLog.placeDetail.error("Failed to open the place of a link", error: error)
                toastManager.show(L10n.string("placeLink.openError"), style: .negative)
            }
        }
    }

    private func open(_ place: MapPlace) {
        coordinator.dismissSheet()
        coordinator.popToRoot()
        selectedTab = .discover
        coordinator.push(.placeDetail(place))
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
                    .environment(\.presentSheet) { coordinator.present(sheet: $0) }
                    .navigationDestination(for: Route.self) { route in
                        profileCoordinator.view(for: route)
                            .environment(profileCoordinator)
                            .environment(\.presentSheet) { coordinator.present(sheet: $0) }
                    }
            }
        case .suggest:
            EmptyView()
        }
    }
}

#Preview {
    MainTabView()
        .environment(AppCoordinator())
        .environment(AuthSession())
}
