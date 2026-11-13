import MapKit
import SwiftUI

struct LocationMapView: View {
    let store: NearbyPlacesStore
    /// Pins are the source of the zoom into the place detail.
    let zoomNamespace: Namespace.ID

    @State private var pinTaps = 0
    @State private var viewModel: LocationMapViewModel
    @State private var searchViewModel: DiscoverSearchViewModel
    @FocusState private var isSearchFocused: Bool
    @State private var ratingPrompt = RatingPromptViewModel()
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(ToastManager.self) private var toasts
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(store: NearbyPlacesStore, zoomNamespace: Namespace.ID) {
        self.store = store
        self.zoomNamespace = zoomNamespace
        _viewModel = State(initialValue: LocationMapViewModel(store: store))
        _searchViewModel = State(
            initialValue: DiscoverSearchViewModel(coordinateProvider: { store.userCoordinate })
        )
    }

    var body: some View {
        Map(position: $viewModel.cameraPosition) {
            userLocationContent
            placeAnnotations
        }
        .tint(.blue)
        .mapStyle(.standard(elevation: .realistic))
        .mapControls {
            #if !(DEBUG && targetEnvironment(simulator))
            MapUserLocationButton()
            #endif
            MapCompass()
        }
        .onMapCameraChange(frequency: .continuous) { context in
            viewModel.updateVisibleRegion(context.region)
        }
        // Pins fade and scale in and out when the grouping changes instead of popping.
        .animation(reduceMotion ? nil : .smooth(duration: 0.3), value: viewModel.displayItems)
        // The error is handed to the app-level toast and consumed, so a repeated failure shows it again.
        .onChange(of: viewModel.errorMessage) { _, message in
            guard let message else { return }
            toasts.show(message, style: .negative)
            viewModel.errorMessage = nil
        }
        .overlay {
            if viewModel.isLoading && viewModel.userCoordinate == nil {
                ProgressView("locationMap.loadingIndicator.title")
                    .padding()
                    .background(.regularMaterial, in: .rect(cornerRadius: 12))
            }
        }
        .overlay {
            if ratingPrompt.isPresented, let pendingRating = ratingPrompt.pendingRating {
                RatingPromptView(
                    placeName: pendingRating.placeName,
                    selectedTag: ratingPrompt.selectedTag,
                    isSubmitting: ratingPrompt.isSubmitting,
                    errorMessage: ratingPrompt.errorMessage,
                    onSelect: { ratingPrompt.select($0) },
                    onSubmit: { Task { await ratingPrompt.submit() } },
                    onDismiss: { ratingPrompt.dismiss() }
                )
                .transition(.opacity)
            }
        }
        .overlay(alignment: .top) {
            discoverControls
        }
        .animation(reduceMotion ? nil : .default, value: ratingPrompt.isPresented)
        .haptic(.toqueSuave, trigger: pinTaps)
        // Kept for the back button of the screens pushed from here; the bar itself is hidden because the
        // search bar and the suggestion button float over the map.
        .navigationTitle("mainTab.discoverTab.title")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .onChange(of: searchViewModel.filter) { _, newFilter in
            viewModel.setFilter(newFilter)
        }
        .task {
            await viewModel.load()
        }
        // The map stays mounted underneath pushed screens, so neither `.task` nor `scenePhase` fires when the
        // user pops back from a check-in. Keying on visibility restarts the monitor on pop and on foreground.
        .task(id: isMonitoringRating) {
            guard isMonitoringRating else { return }
            await ratingPrompt.monitorLeaving()
            // `monitorLeaving` swallows cancellation and returns. A reload started after that
            // is the request URLSession then cancels, which used to toast "couldn't load places".
            guard !Task.isCancelled, isMonitoringRating else { return }
            await viewModel.reloadPlaces()
        }
        // Another screen (or the tab bar) may have refreshed the shared places while the map was out of sight.
        .onChange(of: store.lastFetchedAt) {
            viewModel.syncPlaces()
        }
        // The pins carry the check-in and itinerary state, so they are refetched the next time the map is
        // visible (`reloadPlaces` above), not while it is hidden underneath another screen.
        .onReceive(NotificationCenter.default.publisher(for: AppNotification.activeItineraryDidChange)) { _ in
            store.markDirty()
        }
        .onReceive(NotificationCenter.default.publisher(for: AppNotification.checkInDidSucceed)) { _ in
            store.markDirty()
        }
    }

    private var pinTransition: AnyTransition {
        reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.7))
    }

    private func open(_ place: MapPlace) {
        coordinator.push(.placeDetail(place))
    }

    /// Opens a place from its pin: the detail zooms out of the pin and the tap is felt.
    private func openPin(_ place: MapPlace) {
        pinTaps += 1
        coordinator.push(.placeDetail(place, zoomsFromPin: true))
    }

    /// Opens a search result: the camera goes to the place and its detail is pushed, as when tapping its pin.
    private func openSearchResult(_ place: MapPlace) {
        isSearchFocused = false
        searchViewModel.reset()
        viewModel.applyCameraRegion(
            MKCoordinateRegion(center: place.coordinate, latitudinalMeters: 600, longitudinalMeters: 600)
        )
        open(place)
    }

    private var discoverControls: some View {
        @Bindable var searchViewModel = searchViewModel
        return VStack(alignment: .trailing, spacing: 8) {
            DiscoverSearchBar(
                text: $searchViewModel.query,
                filter: $searchViewModel.filter,
                isFocused: $isSearchFocused,
                onSubmit: { searchViewModel.submit() }
            )

            if searchViewModel.showsResultsPanel {
                DiscoverSearchResultsPanel(
                    phase: searchViewModel.phase,
                    results: searchViewModel.results,
                    onSelect: openSearchResult
                )
                .transition(.opacity.combined(with: .scale(scale: 0.96, anchor: .top)))
            } else {
                DiscoverSuggestButton {
                    isSearchFocused = false
                    coordinator.present(sheet: .suggestPlace)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.9, anchor: .topTrailing)))
            }
        }
        .motion(Motion.suave, value: searchViewModel.showsResultsPanel)
        .padding(.horizontal, 16)
    }

    private func expand(_ cluster: MapPinCluster) {
        pinTaps += 1
        let region = viewModel.focusRegion(on: cluster)
        if reduceMotion {
            viewModel.applyCameraRegion(region)
        } else {
            withAnimation(.smooth(duration: 0.45)) {
                viewModel.applyCameraRegion(region)
            }
        }
    }

    private var isMonitoringRating: Bool {
        coordinator.path.isEmpty && scenePhase == .active
    }

    @MapContentBuilder
    private var placeAnnotations: some MapContent {
        ForEach(viewModel.displayItems) { item in
            switch item {
            case .place(let place):
                Annotation("", coordinate: place.coordinate, anchor: .bottom) {
                    Button {
                        openPin(place)
                    } label: {
                        LocationPinView(category: place.category, style: place.pinStyle)
                    }
                    .buttonStyle(MapPinButtonStyle())
                    .matchedTransitionSource(id: place.id, in: zoomNamespace)
                    .accessibilityLabel(place.displayName)
                    .transition(pinTransition)
                }
                .annotationTitles(.hidden)
            case .cluster(let cluster):
                Annotation("", coordinate: cluster.coordinate, anchor: .bottom) {
                    Button {
                        expand(cluster)
                    } label: {
                        LocationClusterPinView(count: cluster.count)
                    }
                    .buttonStyle(MapPinButtonStyle())
                    .accessibilityLabel(
                        String(
                            localized: "locationMap.clusterPin.accessibilityLabel \(cluster.count)"
                        )
                    )
                    .transition(pinTransition)
                }
            }
        }
    }

    @MapContentBuilder
    private var userLocationContent: some MapContent {
        #if DEBUG && targetEnvironment(simulator)
        if let coordinate = viewModel.userCoordinate {
            Annotation("", coordinate: coordinate.clLocationCoordinate2D) {
                SimulatorUserLocationMarker()
                    .accessibilityLabel("locationMap.userLocation.accessibilityLabel")
            }
        }
        #else
        UserAnnotation()
        #endif
    }
}

#Preview {
    @Previewable @Namespace var placeZoom
    LocationMapView(store: NearbyPlacesStore(), zoomNamespace: placeZoom)
        .environment(AppCoordinator())
        .environment(ToastManager())
}
