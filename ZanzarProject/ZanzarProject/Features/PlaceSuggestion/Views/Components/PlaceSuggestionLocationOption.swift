import SwiftUI

/// One of the two radio-style pills at the top of "Sugerir um lugar" (Figma "Opção / ..."): use the user's
/// location, or look for another place.
struct PlaceSuggestionLocationOption: View {
    let titleKey: LocalizedStringKey
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: isSelected ? "inset.filled.circle" : "circle")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(isSelected ? Color.brandPurple500 : Color.brandOptionIdleIcon)
                    .accessibilityHidden(true)

                Text(titleKey)
                    .font(.system(size: 14, weight: .semibold))
                    .tracking(0.1)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
            .background(isSelected ? Color.brandPurple50 : Color.brandNeutral50, in: .capsule)
            .overlay {
                Capsule()
                    .strokeBorder(isSelected ? Color.brandPurple400 : Color.brandOptionBorder, lineWidth: 1)
            }
            .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    VStack(spacing: 8) {
        PlaceSuggestionLocationOption(titleKey: "placeSuggestion.locationOption.useMine", isSelected: true) {}
        PlaceSuggestionLocationOption(titleKey: "placeSuggestion.locationOption.other", isSelected: false) {}
    }
    .padding()
}
