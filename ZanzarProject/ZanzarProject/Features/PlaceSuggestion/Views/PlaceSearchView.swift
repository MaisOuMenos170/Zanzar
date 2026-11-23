import SwiftUI

/// The search of "Sugerir um lugar" on a screen of its own, with the system's search field (`searchable`) at the
/// top and the results taking the rest of the height. The search itself (the pause after typing, the results)
/// lives in the view model. Choosing a result, choosing to fill the place in by hand, or cancelling closes it.
struct PlaceSearchView: View {
    @Bindable var viewModel: PlaceSuggestionViewModel
    let onClose: () -> Void

    @State private var isSearchActive = false

    var body: some View {
        NavigationStack {
            ScrollView {
                content
                    .padding(.vertical, 8)
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollBounceBehavior(.basedOnSize)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.brandNeutral50)
            .screenTitle("placeSuggestion.search.title")
            .searchable(
                text: $viewModel.query,
                isPresented: $isSearchActive,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: Text("placeSuggestion.searchField.placeholder")
            )
            .onSubmit(of: .search) { viewModel.submitSearch() }
            // The system's Cancel button ends the search, and with it this screen.
            .onChange(of: isSearchActive) {
                if !isSearchActive { onClose() }
            }
            .task { isSearchActive = true }
        }
    }

    @ViewBuilder
    private var content: some View {
        if let message = viewModel.searchErrorMessage {
            Text(message)
                .font(.footnote)
                .foregroundStyle(Color.brandErrorRed)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
        } else if viewModel.isSearching && viewModel.results.isEmpty {
            SkeletonRows()
                .padding(.horizontal, 16)
                .padding(.top, 16)
        } else if viewModel.hasSearched {
            if viewModel.results.isEmpty {
                emptyState
            } else {
                resultsList
            }
        }
    }

    /// One row per place, with a divider between them.
    private var resultsList: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(spacing: 0) {
                ForEach(viewModel.results) { place in
                    PlaceSearchResultRow(place: place) {
                        viewModel.select(place)
                        onClose()
                    }
                    if place.id != viewModel.results.last?.id {
                        Divider().padding(.leading, 68)
                    }
                }
            }

            Button("placeSuggestion.manual.button") {
                viewModel.enterManually()
                onClose()
            }
            .font(.footnote.weight(.semibold))
            .tint(Color.brandPurple500)
            .padding(.horizontal, 16)
        }
    }

    /// The same no-results text as the lists of the app. The view model already opened the manual form for a
    /// search without results; going back shows it.
    private var emptyState: some View {
        ListNoResultsView(
            kind: .empty(
                title: "placeSuggestion.search.empty.title \(viewModel.trimmedQuery)",
                message: "placeSuggestion.search.empty.message"
            ),
            action: .init(title: "placeSuggestion.search.fillByHand", perform: onClose)
        )
    }
}

#Preview {
    PlaceSearchView(viewModel: PlaceSuggestionViewModel(), onClose: {})
}
