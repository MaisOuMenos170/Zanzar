import SwiftUI

struct ItineraryListView: View {
    let sheetCoordinator: AppCoordinator

    @State private var viewModel = ItineraryListViewModel()
    @State private var mediaPolicy = PlaceMediaAccessPolicy.shared
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(NearbyPlacesStore.self) private var nearbyPlacesStore

    /// The carousel only needs the closest places; each card loads a photo from the API.
    private static let nearbyPlacesLimit = 10

    var body: some View {
        @Bindable var viewModel = viewModel
        Group {
            if viewModel.itineraries.isEmpty, viewModel.isLoading {
                ProgressView("itinerary.loadingIndicator.title")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage = viewModel.errorMessage, viewModel.itineraries.isEmpty {
                ContentUnavailableView {
                    Label("itinerary.errorState.title", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(errorMessage)
                } actions: {
                    Button("itinerary.errorState.retryButton.title") {
                        Task { await viewModel.load(force: true) }
                    }
                    .disabled(viewModel.isLoading)
                }
            } else {
                listContent
            }
        }
        .background(Color(.systemBackground))
        .toolbar(.hidden, for: .navigationBar)
        .task {
            // The map normally has the places already; this only fetches if it has not, or they went stale.
            async let places: Void = refreshNearbyPlaces()
            await viewModel.load()
            await places
        }
        .refreshable {
            async let places: Void = refreshNearbyPlaces(force: true)
            await viewModel.load(force: true)
            await places
        }
        // Activating or abandoning an itinerary posts this once; it is the only trigger, so the progress card
        // is not fetched a second time when the sheet closes.
        .onReceive(NotificationCenter.default.publisher(for: AppNotification.activeItineraryDidChange)) { _ in
            Task { await viewModel.refreshActiveItinerary() }
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

    private var nearbyPlaces: [PlaceDetailNearbyPlace] {
        nearbyPlacesStore.places
            .sorted { ($0.distanceMeters ?? .infinity) < ($1.distanceMeters ?? .infinity) }
            .prefix(Self.nearbyPlacesLimit)
            .map(PlaceDetailNearbyPlace.init(mapPlace:))
    }

    private func refreshNearbyPlaces(force: Bool = false) async {
        if force {
            try? await nearbyPlacesStore.refresh()
        } else {
            try? await nearbyPlacesStore.refreshIfNeeded()
        }
    }

    private var listContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    if viewModel.activeItinerary == nil {
                        Text("itinerary.list.header.title")
                            .font(.title2.bold())
                        Text("itinerary.list.header.subtitle")
                            .font(.caption.weight(.light))
                            .foregroundStyle(.primary)
                    } else {
                        Text("itinerary.activeCard.title")
                            .font(.title2.bold())
                    }
                }

                if let activeItinerary = viewModel.activeItinerary {
                    ActiveItineraryProgressCard(activeItinerary: activeItinerary) {
                        sheetCoordinator.present(sheet: .itineraryDetail(slug: activeItinerary.slug))
                    }
                }

                if !viewModel.itineraries.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("itinerary.list.sections.itineraries")
                            .font(.callout.bold())

                        ForEach(viewModel.itineraries) { itinerary in
                            ItineraryCard(itinerary: itinerary) {
                                sheetCoordinator.present(sheet: .itineraryDetail(slug: itinerary.slug))
                            }
                        }
                    }
                }

                if !nearbyPlaces.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("itinerary.list.sections.nearby")
                            .font(.callout.bold())

                        NearbyPlacesCarousel(places: nearbyPlaces, mediaPolicy: mediaPolicy) { place in
                            coordinator.push(.placeDetail(place))
                        }
                    }
                }
            }
            .padding(16)
        }
        .scrollIndicators(.hidden)
    }
}

#Preview {
    NavigationStack {
        ItineraryListView(sheetCoordinator: AppCoordinator())
            .environment(AppCoordinator())
            .environment(NearbyPlacesStore())
    }
}
