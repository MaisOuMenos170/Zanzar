import SwiftUI
import TipKit

/// "Minhas sugestões": the latest places the user suggested, with a link to all of them.
struct ProfileSuggestionsSection: View {
    let onSeeMore: () -> Void

    @State private var viewModel = MySuggestionsViewModel()
    @Environment(AppCoordinator.self) private var coordinator

    private let mySuggestionsTip = ProfileMySuggestionsTip()
    private let previewCount = 3

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ProfileSectionHeader(title: "profile.suggestionsSection.mySuggestions.title", onSeeMore: onSeeMore)
                .popoverTip(mySuggestionsTip, arrowEdge: .bottom)

            if viewModel.suggestions.isEmpty {
                if viewModel.hasLoaded {
                    ListEmptyState(message: "profile.suggestionsSection.empty")
                }
            } else {
                ListCard {
                    ForEach(viewModel.suggestions.prefix(previewCount)) { suggestion in
                        MySuggestionRow(suggestion: suggestion)
                    }
                }
            }
        }
        // Reloads when "all suggestions" or the suggestion sheet is closed: the list may have changed.
        .task(id: coordinator.path.isEmpty) {
            guard coordinator.path.isEmpty else { return }
            await viewModel.load()
        }
    }
}
