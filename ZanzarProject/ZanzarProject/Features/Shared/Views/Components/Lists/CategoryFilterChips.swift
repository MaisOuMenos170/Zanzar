import SwiftUI

/// A scrolling row of chips: the selected one is filled coral, the others are outlined.
struct CategoryFilterChips: View {
    @Binding var selection: CategoryFilter

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 4) {
                ForEach(CategoryFilter.allCases) { filter in
                    chip(filter)
                }
            }
        }
        .scrollIndicators(.hidden)
        .haptic(.selecao, trigger: selection)
    }

    private func chip(_ filter: CategoryFilter) -> some View {
        let isSelected = selection == filter
        return Button {
            selection = filter
        } label: {
            Text(filter.titleKey)
                .typography(isSelected ? .caption3 : .caption1)
                .foregroundStyle(isSelected ? Color.brandNeutral50 : Color.brandNeutral600)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .frame(minHeight: 32)
                .background {
                    if isSelected {
                        Capsule().fill(Color.brandOrange600)
                    } else {
                        Capsule().strokeBorder(Color.brandChipBorder, lineWidth: 1)
                    }
                }
                .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    @Previewable @State var filter = CategoryFilter.all
    CategoryFilterChips(selection: $filter)
        .padding()
        .background(Color.profileBackground)
}
