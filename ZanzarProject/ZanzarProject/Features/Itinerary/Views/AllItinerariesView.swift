import SwiftUI

/// "Todos os roteiros" (Figma "checkin v2", nodes 1814:3197 and 1931:3731).
struct AllItinerariesView: View {
    @State private var viewModel = AllItinerariesViewModel()
    @Environment(\.presentSheet) private var presentSheet

    var body: some View {
        ListScreenScaffold(
            title: "itinerary.all.title",
            searchPrompt: "itinerary.all.search.prompt",
            searchText: $viewModel.searchText,
            count: Text("itinerary.all.count \(viewModel.visibleItineraries.count)"),
            filters: {
                FilterChips(options: ItineraryThemeFilter.allCases, selection: $viewModel.filter, title: \.titleKey)
            },
            content: { content }
        )
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
    }

    @ViewBuilder
    private var content: some View {
        if let errorMessage = viewModel.errorMessage, viewModel.itineraries.isEmpty {
            ContentUnavailableView {
                Label("itinerary.errorState.title", systemImage: "exclamationmark.triangle")
            } description: {
                Text(errorMessage)
            } actions: {
                Button("itinerary.errorState.retryButton.title") {
                    Task { await viewModel.load() }
                }
            }
        } else if !viewModel.hasLoaded {
            ListLoadingView()
        } else if viewModel.visibleItineraries.isEmpty {
            ListNoResultsView(kind: emptyKind)
        } else {
            LazyVStack(spacing: 8) {
                ForEach(viewModel.visibleItineraries) { itinerary in
                    ItineraryCard(itinerary: itinerary) {
                        presentSheet?(.itineraryDetail(slug: itinerary.slug))
                    }
                }
            }
        }
    }

    private var emptyKind: ListNoResultsView.Kind {
        if viewModel.itineraries.isEmpty {
            return .empty(title: "itinerary.all.empty.title", message: "itinerary.all.empty.message")
        }
        let query = viewModel.trimmedQuery
        guard !query.isEmpty else { return .filtered }
        return .custom(title: "itinerary.all.noResults.title \(query)", message: "itinerary.all.noResults.message")
    }
}

#Preview {
    NavigationStack {
        AllItinerariesView()
    }
}
