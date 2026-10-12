import SwiftUI

struct ItineraryListView: View {
    let sheetCoordinator: AppCoordinator

    @State private var viewModel = ItineraryListViewModel()
    @State private var mediaPolicy = PlaceMediaAccessPolicy.shared
    @Environment(AppCoordinator.self) private var coordinator

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
                        Task { await viewModel.load() }
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
            await viewModel.load()
        }
        .refreshable {
            await viewModel.load()
        }
        .onChange(of: sheetCoordinator.presentedSheet) { _, newValue in
            guard newValue == nil else { return }
            Task { await viewModel.refreshActiveItinerary() }
        }
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

                if !viewModel.nearbyPlaces.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("itinerary.list.sections.nearby")
                            .font(.callout.bold())

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
