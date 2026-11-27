import SwiftUI

struct AllCheckInsView: View {
    @State private var viewModel = ProfileCheckInsViewModel()
    @State private var searchText = ""
    @State private var filter = CategoryFilter.all

    private var visibleCheckIns: [ProfileCheckIn] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return viewModel.checkIns.filter { checkIn in
            filter.includes(checkIn.sealCategory)
                && (query.isEmpty || checkIn.placeName?.localizedStandardContains(query) == true)
        }
    }

    var body: some View {
        ListScreenScaffold(
            title: "profile.allCheckIns.title",
            searchPrompt: "profile.search.place.prompt",
            searchText: $searchText,
            filter: $filter,
            count: Text("profile.allCheckIns.count \(visibleCheckIns.count)")
        ) {
            VStack(spacing: 16) {
                content
                if viewModel.hasMore && !visibleCheckIns.isEmpty || viewModel.loadMoreFailed {
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
                MascotStateLabel(.sad, "profile.errorState.title")
            } description: {
                Text(errorMessage)
            } actions: {
                Button("profile.errorState.retryButton.title") {
                    Task { await viewModel.load() }
                }
            }
        } else if viewModel.checkIns.isEmpty && !viewModel.hasLoaded {
            ListLoadingView()
        } else if visibleCheckIns.isEmpty && viewModel.hasMore {
            // The check-ins that match may be on a page that is not loaded yet.
            loadMoreFooter
        } else if visibleCheckIns.isEmpty {
            ListNoResultsView(
                hasItems: !viewModel.checkIns.isEmpty,
                query: searchText,
                emptyTitle: "list.empty.checkIns.title",
                emptyMessage: "list.empty.checkIns.message",
                notFoundMessage: "list.noResults.place.message"
            )
        } else {
            LazyVStack(spacing: 16) {
                ForEach(Array(visibleCheckIns.enumerated()), id: \.element.id) { index, checkIn in
                    NavigationLink(value: Route.placeDetail(checkIn.mapPlace)) {
                        ProfileCheckInCard(checkIn: checkIn, tone: .tone(at: index), layout: .wide)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("profile.checkInCard.openDetailsHint")
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
