import MapKit
import SwiftUI

struct LocationMapView: View {
    @State private var viewModel = LocationMapViewModel()
    @Environment(AppCoordinator.self) private var coordinator

    var body: some View {
        Map(position: $viewModel.cameraPosition) {
            UserAnnotation()
        }
        .mapStyle(.standard(elevation: .realistic))
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
            await viewModel.loadUserLocation()
        }
        .ignoresSafeArea()
    }
}

#Preview {
    LocationMapView()
        .environment(AppCoordinator())
}
