import SwiftUI

/// One place found by the search. Tapping it selects it for the suggestion.
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
                    .foregroundStyle(isSelected ? Color("WelcomePrimary") : Color.secondary)

                VStack(alignment: .leading, spacing: 1) {
                    Text(place.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)
                    Text(place.address)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(
                isSelected ? Color("PlaceSuggestionOptionSelectedBackground") : Color(.systemBackground),
                in: .rect(cornerRadius: 8)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(
                        isSelected ? Color("WelcomePrimary") : Color("PlaceSuggestionOptionBorder"),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            }
            .contentShape(.rect(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    PlaceSuggestionResultRow(
        place: SuggestedPlace(
            osmType: "node",
            osmID: 1,
            name: "Jardim Botânico",
            address: "Rua Engenheiro Ostoja Roguski, Curitiba",
            latitude: -25.44,
            longitude: -49.24
        ),
        isSelected: true,
        action: {}
    )
    .padding()
}
