import MapKit
import SwiftUI

struct ItineraryDetailView: View {
    @Bindable var viewModel: ItineraryDetailViewModel
    let onItineraryChanged: () -> Void
    @Environment(AppCoordinator.self) private var coordinator

    var body: some View {
        Group {
            if let detail = viewModel.detail {
                detailContent(for: detail)
            } else if viewModel.isLoading {
                ProgressView("itinerary.detail.loadingIndicator.title")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ContentUnavailableView {
                    Label("itinerary.detail.errorState.title", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(viewModel.errorMessage ?? "itinerary.detail.errorState.message")
                } actions: {
                    Button("itinerary.detail.errorState.retryButton.title") {
                        Task { await viewModel.load() }
                    }
                }
            }
        }
        .task {
            await viewModel.load()
        }
        .alert("itinerary.detail.actionError.title", isPresented: $viewModel.showsActionError) {
            Button("itinerary.detail.actionError.dismissButton.title", role: .cancel) {
                viewModel.actionErrorMessage = nil
            }
        } message: {
            if let actionErrorMessage = viewModel.actionErrorMessage {
                Text(actionErrorMessage)
            }
        }
    }

    @ViewBuilder
    private func detailContent(for detail: ItineraryDetail) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(detail.name)
                    .font(.title2.bold())

                if !detail.objectives.isEmpty {
                    ItineraryObjectiveTagsView(objectives: detail.objectives)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("itinerary.detail.placesCount \(detail.placesCount)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("itinerary.detail.completedCount \(detail.completedCount)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Text(detail.description)
                    .font(.body)
                    .foregroundStyle(.primary)

                switch detail.routeType {
                case .free:
                    ItineraryFreeRouteStampsView(count: detail.placesCount)
                case .fixed:
                    ItineraryFixedRouteMapView(places: detail.places)
                    ItinerarySuggestedRouteView(places: detail.places)
                }

                actionButtons
            }
            .padding(16)
        }
        .scrollIndicators(.hidden)
    }

    @ViewBuilder
    private var actionButtons: some View {
        if viewModel.isCurrentItineraryActive {
            Button("itinerary.detail.abandonButton", role: .destructive) {
                Task {
                    if await viewModel.abandonItinerary() {
                        onItineraryChanged()
                        coordinator.dismissSheet()
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isPerformingAction)
        } else {
            VStack(alignment: .leading, spacing: 8) {
                Button("itinerary.detail.startButton") {
                    Task {
                        if await viewModel.activateItinerary() {
                            onItineraryChanged()
                            coordinator.dismissSheet()
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isPerformingAction || viewModel.hasDifferentActiveItinerary)

                if viewModel.hasDifferentActiveItinerary {
                    Text("itinerary.detail.actionError.alreadyActive")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

private struct ItineraryObjectiveTagsView: View {
    let objectives: [String]

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(objectives, id: \.self) { objective in
                    Text(objective)
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color("PlaceDetailTagGreenBackground"))
                        .clipShape(.capsule)
                }
            }
        }
        .scrollIndicators(.hidden)
    }
}

private struct ItineraryFreeRouteStampsView: View {
    let count: Int

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 72), spacing: 12)], spacing: 12) {
            ForEach(0..<count, id: \.self) { _ in
                ItineraryStampView(state: .preview, size: 72)
            }
        }
    }
}

private struct ItineraryFixedRouteMapView: View {
    let places: [ItineraryDetailPlace]
    @State private var cameraPosition: MapCameraPosition = .automatic

    var body: some View {
        Map(position: $cameraPosition) {
            ForEach(places) { place in
                Marker(place.name, coordinate: place.coordinate)
            }
        }
        .frame(height: 220)
        .clipShape(.rect(cornerRadius: 12))
        .onAppear {
            cameraPosition = .region(region(for: places))
        }
    }

    private func region(for places: [ItineraryDetailPlace]) -> MKCoordinateRegion {
        guard !places.isEmpty else {
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: -25.43, longitude: -49.27),
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        }

        let latitudes = places.map(\.latitude)
        let longitudes = places.map(\.longitude)
        let minLat = latitudes.min() ?? places[0].latitude
        let maxLat = latitudes.max() ?? places[0].latitude
        let minLng = longitudes.min() ?? places[0].longitude
        let maxLng = longitudes.max() ?? places[0].longitude
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLng + maxLng) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: max(0.01, (maxLat - minLat) * 1.6 + 0.01),
            longitudeDelta: max(0.01, (maxLng - minLng) * 1.6 + 0.01)
        )
        return MKCoordinateRegion(center: center, span: span)
    }
}

private struct ItinerarySuggestedRouteView: View {
    let places: [ItineraryDetailPlace]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("itinerary.detail.suggestedRoute.title")
                .font(.body.bold())

            ForEach(places.enumerated(), id: \.element.id) { index, place in
                HStack(alignment: .top, spacing: 12) {
                    Text("\(index + 1)")
                        .font(.caption.bold())
                        .frame(width: 24, height: 24)
                        .background(Color("PlaceDetailTagGreenBackground"))
                        .clipShape(.circle)

                    Text(place.name)
                        .font(.subheadline)
                }
            }
        }
    }
}

private extension ItineraryDetailPlace {
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

#Preview {
    NavigationStack {
        ItineraryDetailView(
            viewModel: ItineraryDetailViewModel(slug: "centro-historico"),
            onItineraryChanged: {}
        )
    }
    .environment(AppCoordinator())
}
