import SwiftUI

struct ListScreenScaffold<Filters: View, Content: View>: View {
    let title: LocalizedStringKey
    let searchPrompt: LocalizedStringKey
    @Binding var searchText: String
    let count: Text
    let filters: Filters
    let content: Content

    init(
        title: LocalizedStringKey,
        searchPrompt: LocalizedStringKey,
        searchText: Binding<String>,
        count: Text,
        @ViewBuilder filters: () -> Filters,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.searchPrompt = searchPrompt
        _searchText = searchText
        self.count = count
        self.filters = filters()
        self.content = content()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ListSearchField(prompt: searchPrompt, text: $searchText)

                VStack(alignment: .leading, spacing: 16) {
                    filters
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
        .screenTitle(title)
    }
}

extension ListScreenScaffold where Filters == EmptyView {
    init(
        title: LocalizedStringKey,
        searchPrompt: LocalizedStringKey,
        searchText: Binding<String>,
        count: Text,
        @ViewBuilder content: () -> Content
    ) {
        self.init(
            title: title,
            searchPrompt: searchPrompt,
            searchText: searchText,
            count: count,
            filters: { EmptyView() },
            content: content
        )
    }
}

extension ListScreenScaffold where Filters == CategoryFilterChips {
    init(
        title: LocalizedStringKey,
        searchPrompt: LocalizedStringKey,
        searchText: Binding<String>,
        filter: Binding<CategoryFilter>,
        allFilterTitle: LocalizedStringKey? = nil,
        count: Text,
        @ViewBuilder content: () -> Content
    ) {
        self.init(
            title: title,
            searchPrompt: searchPrompt,
            searchText: searchText,
            count: count,
            filters: { CategoryFilterChips(selection: filter, allTitle: allFilterTitle) },
            content: content
        )
    }
}
