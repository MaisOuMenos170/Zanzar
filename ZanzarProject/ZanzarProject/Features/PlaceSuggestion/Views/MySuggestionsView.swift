import SwiftUI

/// The places the user suggested and where each one stands. Reached from the profile.
struct MySuggestionsView: View {
    @State private var viewModel = MySuggestionsViewModel()

    var body: some View {
        Group {
            if viewModel.suggestions.isEmpty && viewModel.hasLoaded {
                ContentUnavailableView(
                    "placeSuggestion.mySuggestions.empty.title",
                    systemImage: "plus.bubble",
                    description: Text("placeSuggestion.mySuggestions.empty.message")
                )
            } else if viewModel.suggestions.isEmpty {
                ProgressView()
            } else {
                List {
                    Section {
                        ForEach(viewModel.suggestions) { suggestion in
                            MySuggestionRow(suggestion: suggestion)
                        }
                    } footer: {
                        Text("placeSuggestion.mySuggestions.footer")
                    }
                }
            }
        }
        .navigationTitle("placeSuggestion.mySuggestions.title")
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
        .alert("placeSuggestion.mySuggestions.errorAlert.title", isPresented: errorIsPresented) {
            Button("placeSuggestion.alert.confirm", role: .cancel) {}
        } message: {
            if let message = viewModel.errorMessage { Text(message) }
        }
    }

    private var errorIsPresented: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil && viewModel.hasLoaded },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )
    }
}
