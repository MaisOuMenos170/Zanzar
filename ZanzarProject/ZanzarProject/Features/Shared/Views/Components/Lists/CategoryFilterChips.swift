import SwiftUI

struct CategoryFilterChips: View {
    @Binding var selection: CategoryFilter
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
