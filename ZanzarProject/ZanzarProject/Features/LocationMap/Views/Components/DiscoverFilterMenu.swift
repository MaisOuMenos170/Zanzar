import SwiftUI

/// The filter button at the end of the search bar. Its options come from `ZanzarPlaceCategory`, plus
/// "No roteiro" for the stops of the roteiro the user is following.
struct DiscoverFilterMenu: View {
    @Binding var filter: PlaceFilter

    var body: some View {
        Menu {
            Toggle("discover.filter.inItinerary", systemImage: "flag", isOn: $filter.onlyInItinerary)

            Section("discover.filter.typesHeader") {
                ForEach(ZanzarPlaceCategory.filterOptions, id: \.self) { category in
                    Toggle(
                        LocalizedStringKey(category.titleKey),
                        systemImage: category.pinIconName,
                        isOn: binding(for: category)
                    )
                }
            }

            if filter.isActive {
                Button("discover.filter.clear", systemImage: "xmark.circle", role: .destructive) {
                    filter = PlaceFilter()
                }
            }
        } label: {
            Image(systemName: "line.3.horizontal.decrease")
                .font(.system(size: 16))
                .foregroundStyle(filter.isActive ? Color.brandPurple500 : Color.primary)
                .overlay(alignment: .topTrailing) {
                    if filter.isActive {
                        Circle()
                            .fill(Color.brandPurple500)
                            .frame(width: 8, height: 8)
                            .offset(x: 5, y: -4)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .motion(Motion.toque, value: filter.isActive)
                // Bigger hit area than the 20pt glyph, without moving it.
                .padding(12)
                .contentShape(.rect)
                .padding(-12)
        }
        .haptic(.selecao, trigger: filter)
        .accessibilityLabel("discover.filter.accessibilityLabel")
        .accessibilityValue(
            filter.isActive ? L10n.string("discover.filter.accessibilityValue", filter.activeCount) : ""
        )
    }

    private func binding(for category: ZanzarPlaceCategory) -> Binding<Bool> {
        Binding(
            get: { filter.categories.contains(category) },
            set: { _ in filter.toggle(category) }
        )
    }
}

#Preview {
    @Previewable @State var filter = PlaceFilter(categories: [.bar], onlyInItinerary: true)
    DiscoverFilterMenu(filter: $filter)
        .padding(40)
}
