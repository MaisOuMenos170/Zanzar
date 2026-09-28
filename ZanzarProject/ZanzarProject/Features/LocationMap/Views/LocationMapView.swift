import MapKit
import SwiftUI

struct LocationMapView: View {
    @State private var viewModel = LocationMapViewModel()
    @Environment(AppCoordinator.self) private var coordinator

    var body: some View {
        Map(position: $viewModel.cameraPosition) {
            userLocationContent
            ForEach(viewModel.places) { place in
                Annotation(place.name, coordinate: place.coordinate) {
                    LocationPinView(iconName: place.pinIconName)
                        .accessibilityLabel(place.name)
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .mapControls {
            MapUserLocationButton()
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
            Annotation("locationMap.userLocation.accessibilityLabel", coordinate: coordinate.clLocationCoordinate2D) {
                SimulatorUserLocationMarker()
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
