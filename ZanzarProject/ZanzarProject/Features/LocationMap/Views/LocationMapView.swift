import MapKit
import SwiftUI

struct LocationMapView: View {
    let store: NearbyPlacesStore

    @State private var viewModel: LocationMapViewModel
    @State private var ratingPrompt = RatingPromptViewModel()
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(ToastPresenter.self) private var toasts
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(store: NearbyPlacesStore) {
        self.store = store
        _viewModel = State(initialValue: LocationMapViewModel(store: store))
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
            toasts.show(message)
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
        .animation(reduceMotion ? nil : .default, value: ratingPrompt.isPresented)
        .navigationTitle("mainTab.discoverTab.title")
        .toolbar(.hidden, for: .navigationBar)
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

    private func expand(_ cluster: MapPinCluster) {
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
                        open(place)
                    } label: {
                        LocationPinView(category: place.category, style: place.pinStyle)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(place.displayName)
                    .transition(pinTransition)
                }
                .annotationTitles(.hidden)
            case .cluster(let cluster):
                Annotation("", coordinate: cluster.coordinate, anchor: .center) {
                    Button {
                        expand(cluster)
                    } label: {
                        LocationClusterPinView(count: cluster.count)
                    }
                    .buttonStyle(.plain)
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
    LocationMapView(store: NearbyPlacesStore())
        .environment(AppCoordinator())
        .environment(ToastPresenter())
}
