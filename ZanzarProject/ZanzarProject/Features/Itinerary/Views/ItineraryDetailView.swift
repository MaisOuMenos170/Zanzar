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

    private func countsRow(for detail: ItineraryDetail) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Label {
                Text("itinerary.detail.placesCount \(detail.placesCount)")
            } icon: {
                Image(systemName: "mappin.and.ellipse")
            }

            Spacer(minLength: 8)

            Label {
                Text("itinerary.detail.completedCount \(detail.completedCount)")
            } icon: {
                Image(systemName: "figure.walk")
            }
        }
        .font(.caption)
        .foregroundStyle(.primary)
    }

    @ViewBuilder
    private func detailContent(for detail: ItineraryDetail) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center, spacing: 12) {
                    Text(detail.name)
                        .font(.title2.bold())
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Button("itinerary.detail.close", systemImage: "xmark", action: coordinator.dismissSheet)
                        .labelStyle(.iconOnly)
                        .buttonStyle(.bordered)
                        .buttonBorderShape(.circle)
                }

                if !detail.objectives.isEmpty {
                    ItineraryObjectiveTagsView(objectives: detail.objectives)
                }

                countsRow(for: detail)

                VStack(alignment: .leading, spacing: 32) {
                    VStack(alignment: .leading, spacing: 12) {
                        switch detail.routeType {
                        case .free:
                            ItineraryFreeRouteStampsView(count: detail.placesCount)
                            if !detail.places.isEmpty {
                                Text("itinerary.detail.eligiblePlaces.title")
                                    .font(.subheadline.bold())
                                ItineraryPlaceListView(places: detail.places)
                            }
                        case .fixed:
                            ItineraryFixedRouteMapView(places: detail.places)
                            ItineraryPlaceListView(places: detail.places)
                        }

                        Text(detail.description)
                            .font(.subheadline.weight(.light))
                            .foregroundStyle(.primary)
                    }

                    actionButtons
                }
            }
            .padding(16)
        }
        .scrollIndicators(.hidden)
    }

    @ViewBuilder
    private var actionButtons: some View {
        if viewModel.isCurrentItineraryActive {
            Button(role: .destructive) {
                Task {
                    if await viewModel.abandonItinerary() {
                        onItineraryChanged()
                        coordinator.dismissSheet()
                    }
                }
            } label: {
                Text("itinerary.detail.abandonButton")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(viewModel.isPerformingAction)
        } else {
            VStack(alignment: .leading, spacing: 8) {
                Button {
                    Task {
                        if await viewModel.activateItinerary() {
                            onItineraryChanged()
                            coordinator.dismissSheet()
                        }
                    }
                } label: {
                    Text("itinerary.detail.startButton")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(Color("TabBarSelected"))
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
                        .font(.caption)
                        .foregroundStyle(Color("PlaceDetailTagGreen"))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 4)
                        .background(Color("PlaceDetailTagGreenBackground"), in: .capsule)
                        .overlay {
                            Capsule()
                                .strokeBorder(Color("PlaceDetailTagGreen"))
                        }
                }
            }
        }
        .scrollIndicators(.hidden)
    }
}

private struct ItineraryFreeRouteStampsView: View {
    let count: Int

    var body: some View {
        ItineraryStampTrack(slots: (0..<count).map { index in
            ItineraryStampTrack.Slot(id: "stamp-\(index)", isEarned: true)
        })
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color("ItineraryProgressBackground"), in: .rect(cornerRadius: 8))
    }
}

private struct ItineraryFixedRouteMapView: View {
    let places: [ItineraryDetailPlace]
    @State private var cameraPosition: MapCameraPosition = .automatic

    var body: some View {
        Map(position: $cameraPosition) {
            if places.count > 1 {
                MapPolyline(coordinates: places.map(\.coordinate))
                    .stroke(Color("TabBarSelected"), lineWidth: 3)
            }
            ForEach(places) { place in
                Annotation(place.name, coordinate: place.coordinate, anchor: .bottom) {
                    LocationPinView(category: place.category, style: .inCurrentItinerary)
                }
            }
        }
        .mapStyle(.standard(elevation: .flat))
        .frame(height: 173)
        .clipShape(.rect(cornerRadius: 8))
        .allowsHitTesting(false)
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

private struct ItineraryPlaceListView: View {
    let places: [ItineraryDetailPlace]

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "mappin.and.ellipse")
                .font(.caption)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                ForEach(places) { place in
                    Text(place.name)
                        .font(.caption)
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("ItineraryPlaceListBackground"), in: .rect(cornerRadius: 8))
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
