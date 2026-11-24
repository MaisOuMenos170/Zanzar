import SwiftUI

struct FilterChips<Option: Hashable & Identifiable>: View {
    let options: [Option]
    @Binding var selection: Option
    let title: (Option) -> LocalizedStringKey

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 4) {
                ForEach(options) { option in
                    chip(option)
                }
            }
        }
        .scrollIndicators(.hidden)
        // Chips scrolling out of the 16pt margin slide off the screen instead of being cut at its edge.
        .scrollClipDisabled()
        .haptic(.selecao, trigger: selection)
    }

    private func chip(_ option: Option) -> some View {
        let isSelected = selection == option
        return Button {
            selection = option
        } label: {
            Text(title(option))
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
