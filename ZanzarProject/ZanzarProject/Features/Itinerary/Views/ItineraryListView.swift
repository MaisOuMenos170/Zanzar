import SwiftUI

struct ItineraryListView: View {
    let sheetCoordinator: AppCoordinator

    @State private var viewModel = ItineraryListViewModel()
    @State private var mediaPolicy = PlaceMediaAccessPolicy.shared
    @Environment(AppCoordinator.self) private var coordinator

    var body: some View {
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
                        Task { await viewModel.load() }
                    }
                    .disabled(viewModel.isLoading)
                }
            } else {
                listContent
            }
        }
        .background(Color(.systemBackground))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 2) {
                    Text("itinerary.list.header.title")
                        .font(.headline)
                    Text("itinerary.list.header.subtitle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .task {
            await viewModel.load()
        }
        .refreshable {
            await viewModel.load()
        }
        .onChange(of: sheetCoordinator.presentedSheet) { _, newValue in
            guard newValue == nil else { return }
            Task { await viewModel.refreshActiveItinerary() }
        }
    }

    private var listContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                ActiveItineraryProgressCard(
                    activeItinerary: viewModel.activeItinerary,
                    onViewDetails: { slug in
                        sheetCoordinator.present(sheet: .itineraryDetail(slug: slug))
                    },
                    onAbandon: {
                        Task { await viewModel.abandonActiveItinerary() }
                    }
                )

                if !viewModel.itineraries.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("itinerary.list.sections.itineraries")
                            .font(.body.bold())

                        ForEach(viewModel.itineraries) { itinerary in
                            ItineraryCard(itinerary: itinerary) {
                                sheetCoordinator.present(sheet: .itineraryDetail(slug: itinerary.slug))
                            }
                        }
                    }
                }

                if !viewModel.nearbyPlaces.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("itinerary.list.sections.nearby")
                            .font(.body.bold())

                        ScrollView(.horizontal) {
                            HStack(spacing: 8) {
                                ForEach(viewModel.nearbyPlaces) { place in
                                    PlaceDetailNearbyPlaceCard(
                                        place: place,
                                        mediaPolicy: mediaPolicy
                                    ) {
                                        coordinator.push(.placeDetail(place.mapPlace))
                                    }
                                }
                            }
                        }
                        .scrollIndicators(.hidden)
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
    }
}
