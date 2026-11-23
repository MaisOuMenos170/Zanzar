import SwiftUI

/// One place found for what was shared. Tapping it selects it for the suggestion. A place may come without a
/// name or without an address, so each line shows only what it has.
struct PlaceSuggestionResultRow: View {
    let place: SuggestedPlace
    let isSelected: Bool
    let action: () -> Void

    private var title: String {
        place.hasName ? place.title : ShortAddress.format(place.title)
    }

    /// The address, which is the title already when the place has no name.
    private var subtitle: String? {
        place.hasName ? place.address.map(ShortAddress.format) : nil
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: isSelected ? "inset.filled.circle" : "circle")
                    .font(.body.weight(.medium))
                    .foregroundStyle(isSelected ? Color("WelcomePrimary") : Color.secondary)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                    if let subtitle {
                        Text(subtitle)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
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
