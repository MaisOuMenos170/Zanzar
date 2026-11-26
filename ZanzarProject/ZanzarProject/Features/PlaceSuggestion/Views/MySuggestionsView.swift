import SwiftUI

struct MySuggestionsView: View {
    @State private var viewModel = MySuggestionsViewModel()
    @State private var searchText = ""

    private var visibleSuggestions: [MySuggestion] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return viewModel.suggestions }
        return viewModel.suggestions.filter {
            $0.displayName.localizedStandardContains(query) || $0.address.localizedStandardContains(query)
        }
    }

    var body: some View {
        ListScreenScaffold(
            title: "placeSuggestion.mySuggestions.title",
            searchPrompt: "placeSuggestion.mySuggestions.search.prompt",
            searchText: $searchText,
            count: Text("placeSuggestion.mySuggestions.count \(visibleSuggestions.count)")
        ) {
            content
        }
        .motion(Motion.suave, value: [viewModel.hasLoaded, viewModel.suggestions.isEmpty])
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
        .alert("placeSuggestion.mySuggestions.errorAlert.title", isPresented: errorIsPresented) {
            Button("placeSuggestion.alert.confirm", role: .cancel) {}
        } message: {
            if let message = viewModel.errorMessage { Text(message) }
        }
    }

    @ViewBuilder
    private var content: some View {
        if let message = viewModel.errorMessage, viewModel.suggestions.isEmpty {
            ListLoadFailedView(message: message) { await viewModel.load() }
        } else if viewModel.suggestions.isEmpty && !viewModel.hasLoaded {
            ListLoadingView()
        } else if visibleSuggestions.isEmpty {
            ListNoResultsView(
                hasItems: !viewModel.suggestions.isEmpty,
                query: searchText,
                emptyTitle: "placeSuggestion.mySuggestions.empty.title",
                emptyMessage: "placeSuggestion.mySuggestions.empty.message",
                notFoundMessage: "list.noResults.suggestion.message",
                offersPlaceSuggestion: true
            )
        } else {
            ListCard {
                ForEach(visibleSuggestions) { suggestion in
                    MySuggestionRow(suggestion: suggestion)
                }
            }
        }
    }

    private var errorIsPresented: Binding<Bool> {
        Binding(
            // With nothing to show the error takes the screen; the alert is for a refresh that failed over a list.
            get: { viewModel.errorMessage != nil && viewModel.hasLoaded && !viewModel.suggestions.isEmpty },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )
    }
}
