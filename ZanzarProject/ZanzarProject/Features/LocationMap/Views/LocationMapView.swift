import MapKit
import SwiftUI

struct LocationMapView: View {
    @State private var viewModel = LocationMapViewModel()
    @State private var ratingPrompt = RatingPromptViewModel()
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(ToastPresenter.self) private var toasts
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        MapReader { proxy in
            map
                .onTapGesture { point in
                    guard let coordinate = proxy.convert(point, from: .local) else { return }
                    selectItem(nearestTo: coordinate)
                }
        }
    }

    private var map: some View {
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
        .animation(.smooth(duration: 0.3), value: viewModel.displayItems)
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
        .animation(.default, value: ratingPrompt.isPresented)
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
            await viewModel.reloadPlaces()
        }
        .onReceive(NotificationCenter.default.publisher(for: AppNotification.activeItineraryDidChange)) { _ in
            Task { await viewModel.reloadPlaces() }
        }
    }

    private static let pinTransition = AnyTransition.opacity.combined(with: .scale(scale: 0.7))

    private func selectItem(nearestTo coordinate: CLLocationCoordinate2D) {
        guard let item = MapPinClustering.nearestItem(to: coordinate, in: viewModel.displayItems) else { return }
        switch item {
        case .place(let place):
            coordinator.push(.placeDetail(place))
        case .cluster(let cluster):
            let region = viewModel.focusRegion(on: cluster)
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
                // The pin does not hit-test itself. Overlapping sprites were opening the neighbor.
                // The map gesture resolves the tap to the nearest coordinate instead.
                Annotation("", coordinate: place.coordinate, anchor: .bottom) {
                    LocationPinView(category: place.category, style: place.pinStyle)
                        .accessibilityLabel(place.displayName)
                        .accessibilityAddTraits(.isButton)
                        .allowsHitTesting(false)
                        .transition(Self.pinTransition)
                }
                .annotationTitles(.hidden)
            case .cluster(let cluster):
                Annotation("", coordinate: cluster.coordinate, anchor: .center) {
                    LocationClusterPinView(count: cluster.count)
                        .accessibilityLabel(
                            String(
                                localized: "locationMap.clusterPin.accessibilityLabel \(cluster.count)"
                            )
                        )
                        .accessibilityAddTraits(.isButton)
                        .allowsHitTesting(false)
                        .transition(Self.pinTransition)
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
    LocationMapView()
        .environment(AppCoordinator())
        .environment(ToastPresenter())
}
