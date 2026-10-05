import MapKit
import SwiftUI

struct LocationMapView: View {
    @State private var viewModel = LocationMapViewModel()
    @State private var ratingPrompt = RatingPromptViewModel()
    @State private var selectedPlaceID: String?
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Map(position: $viewModel.cameraPosition, selection: $selectedPlaceID) {
            userLocationContent
            placeAnnotations
        }
        .onChange(of: selectedPlaceID) { _, placeID in
            guard let placeID,
                  let place = viewModel.places.first(where: { $0.id == placeID }) else { return }
            selectedPlaceID = nil
            coordinator.push(.placeDetail(place))
        }
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
        .overlay(alignment: .top) {
            if let errorMessage = viewModel.errorMessage {
                LocationMapErrorBanner(message: errorMessage)
                    .padding()
            }
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
        .task {
            await viewModel.load()
        }
        // The map stays mounted underneath pushed screens, so neither `.task` nor `scenePhase` fires when the
        // user pops back from a check-in. Keying on visibility restarts the monitor on pop and on foreground.
        .task(id: isMonitoringRating) {
            guard isMonitoringRating else { return }
            await ratingPrompt.monitorLeaving()
        }
        .ignoresSafeArea()
    }

    private var isMonitoringRating: Bool {
        coordinator.path.isEmpty && scenePhase == .active
    }

    @MapContentBuilder
    private var placeAnnotations: some MapContent {
        ForEach(viewModel.displayItems) { item in
            switch item {
            case .place(let place):
                Annotation(place.name, coordinate: place.coordinate, anchor: .bottom) {
                    LocationPinView(iconName: place.pinIconName)
                        .accessibilityLabel(place.name)
                        .accessibilityAddTraits(.isButton)
                }
                .tag(place.id)
            case .cluster(let cluster):
                Annotation("", coordinate: cluster.coordinate, anchor: .center) {
                    Button {
                        let region = viewModel.focusRegion(on: cluster)
                        withAnimation(.smooth(duration: 0.45)) {
                            viewModel.applyCameraRegion(region)
                        }
                    } label: {
                        LocationClusterPinView(count: cluster.count)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(
                        String(
                            localized: "locationMap.clusterPin.accessibilityLabel \(cluster.count)"
                        )
                    )
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
}
