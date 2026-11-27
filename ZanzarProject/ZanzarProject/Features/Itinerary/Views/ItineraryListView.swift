import SwiftUI
import TipKit

struct ItineraryListView: View {
    let sheetCoordinator: AppCoordinator

    @State private var viewModel = ItineraryListViewModel()
    /// The list rises in once when it first loads, not each time the tab is shown again.
    @State private var contentShown = false
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(NearbyPlacesStore.self) private var nearbyPlacesStore

    // Tips
    private let startItineraryTip = CheckInStartItineraryTip()
    private static let featuredCount = 2
    private static let nearbyCount = 8

    var body: some View {
        @Bindable var viewModel = viewModel
        Group {
            if viewModel.itineraries.isEmpty, viewModel.isLoading {
                ItineraryListSkeleton()
            } else if let errorMessage = viewModel.errorMessage, viewModel.itineraries.isEmpty {
                ContentUnavailableView {
                    MascotStateLabel(.sad, "itinerary.errorState.title")
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
        .background(Color.profileBackground)
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

    private func nextStopDistance(of itinerary: ActiveItinerary) -> String? {
        guard let placeID = ActiveItineraryProgress(itinerary).nextPlaceID else { return nil }
        return nearbyPlacesStore.places.first { $0.id == placeID }?.roundedDistanceText
    }

    /// The places closest to the user, nearest first.
    private var nearbyPlaces: [MapPlace] {
        nearbyPlacesStore.places
            .filter { $0.distanceMeters != nil }
            .sorted { ($0.distanceMeters ?? .infinity) < ($1.distanceMeters ?? .infinity) }
            .prefix(Self.nearbyCount)
            .map { $0 }
    }

    private func refreshNearbyPlaces(force: Bool = false) async {
        if force {
            try? await nearbyPlacesStore.refresh()
        } else {
            try? await nearbyPlacesStore.refreshIfNeeded()
        }
    }

    private func sectionTitle(_ key: LocalizedStringKey) -> some View {
        Text(key)
            .scaledFont(size: 20, weight: .bold, design: .rounded)
            .tracking(0.15)
            .foregroundStyle(.black)
            .accessibilityAddTraits(.isHeader)
    }

    private var listContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                header
                    .entrance(contentShown, order: 0)

                if !viewModel.itineraries.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(title: "itinerary.list.sections.featured") {
                            coordinator.push(.allItineraries)
                        }
                        .entrance(contentShown, order: 2)

                        VStack(spacing: 8) {
                            let featured = viewModel.itineraries.prefix(Self.featuredCount)
                            ForEach(featured.enumerated(), id: \.element.id) { index, itinerary in
                                ItineraryCard(itinerary: itinerary) {
                                    sheetCoordinator.present(sheet: .itineraryDetail(slug: itinerary.slug))
                                }
                                .entrance(contentShown, order: 2 + index)
                            }
                        }
                    }
                }

                if !nearbyPlaces.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(title: "itinerary.list.sections.nearby") {
                            coordinator.push(.allPlaces)
                        }
                        nearbyGrid
                    }
                    .entrance(contentShown, order: 4)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 16)
            // Starting or leaving a roteiro swaps the progress card in or out instead of cutting.
            .motion(Motion.assentar, value: viewModel.activeItinerary?.slug)
            .onAppear {
                contentShown = true
            }
        }
        .scrollIndicators(.hidden)
    }

    /// "Check-in" and, under it, the roteiro in progress, or the dashed hint to pick one.
    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let activeItinerary = viewModel.activeItinerary {
                sectionTitle("itinerary.list.header.title")
                    .tipAbove(startItineraryTip)

                ActiveItineraryProgressCard(
                    activeItinerary: activeItinerary,
                    nextStopDistance: nextStopDistance(of: activeItinerary)
                ) {
                    sheetCoordinator.present(sheet: .itineraryDetail(slug: activeItinerary.slug))
                    CheckInStartItineraryTip.hasStartedItinerary = true
                }
                .transition(.opacity.combined(with: .scale(scale: 0.96, anchor: .top)))
            } else {
                sectionTitle("itinerary.list.header.title")

                CheckInEmptySlot()
            }
        }
    }

    private var nearbyGrid: some View {
        let places = nearbyPlaces
        return Grid(horizontalSpacing: 8, verticalSpacing: 8) {
            ForEach(Array(stride(from: 0, to: places.count, by: 2)), id: \.self) { rowStart in
                GridRow {
                    ForEach(rowStart..<min(rowStart + 2, places.count), id: \.self) { index in
                        CheckInPlaceTile(
                            place: places[index],
                            palette: CheckInPlaceTile.Palette(position: index),
                            isSecondRow: rowStart > 0
                        ) {
                            coordinator.push(.placeDetail(places[index]))
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ItineraryListView(sheetCoordinator: AppCoordinator())
            .environment(AppCoordinator())
            .environment(NearbyPlacesStore())
    }
}
