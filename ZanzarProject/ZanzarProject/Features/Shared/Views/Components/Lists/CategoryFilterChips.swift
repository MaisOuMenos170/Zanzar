import SwiftUI

struct CategoryFilterChips: View {
    @Binding var selection: CategoryFilter
    /// What the first chip says when it is not "Todos" (the places list calls it "Mais próximos").
    var allTitle: LocalizedStringKey?

    var body: some View {
        FilterChips(options: CategoryFilter.allCases, selection: $selection) { filter in
            if filter == .all, let allTitle { allTitle } else { filter.titleKey }
        }
    }
}

#Preview {
    @Previewable @State var filter = CategoryFilter.all
    CategoryFilterChips(selection: $filter)
        .padding()
        .background(Color.profileBackground)
}
