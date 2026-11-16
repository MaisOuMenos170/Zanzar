import SwiftUI

/// "Todos os check-ins": every check-in as a card, filtered by category and place name.
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
            content
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
        } else if viewModel.checkIns.isEmpty && viewModel.hasLoaded {
            ContentUnavailableView("profile.recentCheckIns.empty", systemImage: "mappin.slash")
        } else if viewModel.checkIns.isEmpty {
            ProgressView()
                .frame(maxWidth: .infinity)
        } else if visibleCheckIns.isEmpty {
            ContentUnavailableView.search(text: searchText)
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
}
