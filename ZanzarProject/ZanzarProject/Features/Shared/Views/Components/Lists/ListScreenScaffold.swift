import SwiftUI

struct ListScreenScaffold<Content: View>: View {
    let title: LocalizedStringKey
    let searchPrompt: LocalizedStringKey
    @Binding var searchText: String
    var filter: Binding<CategoryFilter>?
    let count: Text
    @ViewBuilder let content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ListSearchField(prompt: searchPrompt, text: $searchText)

                VStack(alignment: .leading, spacing: 16) {
                    if let filter {
                        CategoryFilterChips(selection: filter)
                    }
                    count
                        .typography(.caption1)
                        .foregroundStyle(Color.black)
                }

                content
            }
            .padding(16)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color.profileBackground)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(title)
                    .typography(.subtitle1)
                    .foregroundStyle(Color.titleBrown)
                    .accessibilityAddTraits(.isHeader)
            }
        }
    }
}
