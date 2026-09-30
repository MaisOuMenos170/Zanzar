import MapKit
import SwiftUI

struct LocationMapView: View {
    @State private var viewModel = LocationMapViewModel()
    @State private var selectedPlaceID: String?
    @Environment(AppCoordinator.self) private var coordinator

    var body: some View {
        Map(position: $viewModel.cameraPosition, selection: $selectedPlaceID) {
            userLocationContent
            ForEach(viewModel.places) { place in
                Annotation(place.name, coordinate: place.coordinate) {
                    LocationPinView(iconName: place.pinIconName)
                        .accessibilityLabel(place.name)
                        .accessibilityAddTraits(.isButton)
                }
                .tag(place.id)
            }
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
        .task {
            await viewModel.load()
        }
        .ignoresSafeArea()
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
