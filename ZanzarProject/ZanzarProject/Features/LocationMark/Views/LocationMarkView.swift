import MapKit
import SwiftUI

struct LocationMarkView: View {
    @State private var viewModel = LocationMarkViewModel()
    @State private var cameraPosition: MapCameraPosition = .automatic

    var body: some View {
        @Bindable var viewModel = viewModel

        LocationMarkMap(position: $cameraPosition, markedLocation: viewModel.markedLocation)
            .overlay {
                if viewModel.isAuthorizationDenied {
                    LocationAccessDeniedView(
                        message: viewModel.errorMessage ?? "",
                        retry: markLocation
                    )
                }
            }
            .safeAreaInset(edge: .bottom) {
                if !viewModel.isAuthorizationDenied {
                    MarkLocationButton(isLoading: viewModel.isLoading, action: markLocation)
                        .frame(maxWidth: .infinity)
                        .background(.bar)
                }
            }
            .navigationTitle("Localização")
            .alert(
                "Não foi possível marcar a localização",
                isPresented: $viewModel.isPresentingError
            ) {
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .sensoryFeedback(.success, trigger: viewModel.markedLocation)
            .onChange(of: viewModel.markedLocation) { _, newMark in
                centerMap(on: newMark)
            }
    }

    private func markLocation() {
        Task {
            await viewModel.markCurrentLocation()
        }
    }

    private func centerMap(on mark: LocationMark?) {
        guard let mark else { return }
        cameraPosition = .region(
            MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: mark.latitude, longitude: mark.longitude),
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        )
    }
}

#Preview {
    NavigationStack {
        LocationMarkView()
    }
    .environment(AppCoordinator())
}
