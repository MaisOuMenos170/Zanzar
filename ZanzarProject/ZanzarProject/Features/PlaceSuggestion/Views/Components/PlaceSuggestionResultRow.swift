import SwiftUI

/// One place Apple Maps found. Tapping it selects it for the suggestion; a result with no name shows its address.
struct PlaceSuggestionResultRow: View {
    let place: SuggestedPlace
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: isSelected ? "inset.filled.circle" : "circle")
                    .font(.body.weight(.medium))
                    .foregroundStyle(isSelected ? Color.brandPurple500 : Color.brandOptionIdleIcon)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 1) {
                    Text(place.hasName ? place.title : ShortAddress.format(place.title))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)
                    // The address is the title already when the place has no name.
                    if place.hasName, let address = place.address {
                        Text(ShortAddress.format(address))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(
                isSelected ? Color.brandPurple50 : Color.brandNeutral50,
                in: .rect(cornerRadius: 8)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(
                        isSelected ? Color.brandPurple400 : Color.brandOptionBorder,
                        lineWidth: 1
                    )
            }
            .contentShape(.rect(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    VStack {
        PlaceSuggestionResultRow(
            place: SuggestedPlace(
                name: "Jardim Botânico",
                address: "Rua Engenheiro Ostoja Roguski, 350, Jardim Botânico, Curitiba - PR, Brasil",
                latitude: -25.44,
                longitude: -49.24
            ),
            isSelected: true,
            action: {}
        )
        PlaceSuggestionResultRow(
            place: SuggestedPlace(
                name: nil,
                address: "Rua Engenheiro Ostoja Roguski, 360, Curitiba - PR, Brasil",
                latitude: -25.44,
                longitude: -49.24
            ),
            isSelected: false,
            action: {}
        )
    }
    .padding()
}
