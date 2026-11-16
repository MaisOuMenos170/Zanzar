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
            ContentUnavailableView("profile.sealsSection.empty", systemImage: "seal")
        } else if viewModel.checkIns.isEmpty {
            ProgressView()
                .frame(maxWidth: .infinity)
        } else if visibleSeals.isEmpty {
            ContentUnavailableView.search(text: searchText)
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
}
