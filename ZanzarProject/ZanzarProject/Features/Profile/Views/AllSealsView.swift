import SwiftUI

/// "Todos os selos": every seal the user earned, filtered by category and name.
struct AllSealsView: View {
    private struct EarnedSeal: Identifiable {
        let id: String
        let category: ZanzarPlaceCategory
    }

    @State private var viewModel = ProfileCheckInsViewModel()
    @State private var searchText = ""
    @State private var filter = CategoryFilter.all

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 15), count: 3)

    private var visibleSeals: [EarnedSeal] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return viewModel.checkIns.compactMap { checkIn -> EarnedSeal? in
            guard let category = checkIn.sealCategory, filter.includes(category) else { return nil }
            guard query.isEmpty || L10n.string(category.titleKey).localizedStandardContains(query) else { return nil }
            return EarnedSeal(id: checkIn.id, category: category)
        }
    }

    var body: some View {
        ListScreenScaffold(
            title: "profile.allSeals.title",
            searchPrompt: "profile.allSeals.search.prompt",
            searchText: $searchText,
            filter: $filter,
            count: Text("profile.allSeals.count \(visibleSeals.count)")
        ) {
            VStack(spacing: 16) {
                content
                if viewModel.hasMore && !visibleSeals.isEmpty || viewModel.loadMoreFailed {
                    loadMoreFooter
                }
            }
        }
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
    }

    @ViewBuilder
    private var content: some View {
        if let errorMessage = viewModel.errorMessage, viewModel.checkIns.isEmpty {
            ContentUnavailableView {
                Label("profile.errorState.title", systemImage: "exclamationmark.triangle")
            } description: {
                Text(errorMessage)
            } actions: {
                Button("profile.errorState.retryButton.title") {
                    Task { await viewModel.load() }
                }
            }
        } else if viewModel.checkIns.isEmpty && !viewModel.hasLoaded {
            ListLoadingView()
        } else if visibleSeals.isEmpty && viewModel.hasMore {
            // The seals that match may be on a page that is not loaded yet.
            loadMoreFooter
        } else if visibleSeals.isEmpty {
            ListNoResultsView(
                hasItems: viewModel.checkIns.contains { $0.sealCategory != nil },
                query: searchText,
                emptyTitle: "list.empty.seals.title",
                emptyMessage: "list.empty.seals.message",
                notFoundMessage: "list.noResults.seal.message"
            )
        } else {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(visibleSeals) { seal in
                    PlaceCategorySealView(category: seal.category, size: 100)
                        .frame(maxWidth: .infinity)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(Text(LocalizedStringKey(seal.category.titleKey)))
                }
            }
        }
    }

    private var loadMoreFooter: some View {
        ListLoadMoreView(
            failed: viewModel.loadMoreFailed,
            onLoadMore: { await viewModel.loadMore() },
            onRetry: { await viewModel.retryLoadMore() }
        )
    }
}
