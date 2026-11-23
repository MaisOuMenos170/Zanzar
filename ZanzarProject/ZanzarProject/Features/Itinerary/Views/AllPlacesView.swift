import SwiftUI

struct AllPlacesView: View {
    @State private var viewModel = AllPlacesViewModel()
    @Environment(NearbyPlacesStore.self) private var nearbyPlacesStore
    @Environment(AppCoordinator.self) private var coordinator

    private let columns = [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)]

    var body: some View {
        let places = viewModel.visiblePlaces(from: nearbyPlacesStore.places)
        ListScreenScaffold(
            title: "places.all.title",
            searchPrompt: "places.all.search.prompt",
            searchText: $viewModel.searchText,
            filter: $viewModel.filter,
            allFilterTitle: "places.all.nearest",
            count: Text("places.all.count \(places.count)")
        ) {
            content(for: places)
        }
        .task { try? await nearbyPlacesStore.refreshIfNeeded() }
        .refreshable { try? await nearbyPlacesStore.refresh() }
    }

    @ViewBuilder
    private func content(for places: [MapPlace]) -> some View {
        if nearbyPlacesStore.places.isEmpty {
            if nearbyPlacesStore.isLoading {
                ListLoadingView()
            } else {
                ListNoResultsView(
                    kind: .empty(title: "places.all.empty.title", message: "places.all.empty.message")
                )
            }
        } else if places.isEmpty {
            ListNoResultsView(
                hasItems: true,
                query: viewModel.searchText,
                emptyTitle: "places.all.empty.title",
                emptyMessage: "places.all.empty.message",
                notFoundMessage: "list.noResults.place.message",
                offersPlaceSuggestion: true
            )
        } else {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(places.enumerated(), id: \.element.id) { index, place in
                    CheckInPlaceTile(
                        place: place,
                        palette: CheckInPlaceTile.Palette(position: index),
                        isSecondRow: index >= columns.count
                    ) {
                        coordinator.push(.placeDetail(place))
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        AllPlacesView()
            .environment(AppCoordinator())
            .environment(NearbyPlacesStore())
    }
}
