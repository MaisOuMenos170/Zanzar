import SwiftUI

/// One place found for what was shared. Tapping it selects it for the suggestion; unlike a row of the search
/// screen of "Sugerir um lugar", it shows whether it is the chosen one.
struct PlaceShareCandidateRow: View {
    let place: SuggestedPlace
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var lineLimit: Int? {
        dynamicTypeSize.isAccessibilitySize ? nil : 2
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: isSelected ? "inset.filled.circle" : "circle")
                    .font(.body.weight(.medium))
                    .foregroundStyle(isSelected ? Color.brandPurple500 : Color.brandOptionIdleIcon)

                VStack(alignment: .leading, spacing: 1) {
                    Text(place.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(lineLimit)
                    // With no name the address is the title already.
                    if place.hasName, let address = place.address {
                        Text(address)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .lineLimit(lineLimit)
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
        PlaceShareCandidateRow(
            place: SuggestedPlace(name: "Padaria Central", address: "Rua XV, 100", latitude: 0, longitude: 0),
            isSelected: true
        ) {}
        PlaceShareCandidateRow(
            place: SuggestedPlace(name: nil, address: "Rua das Flores, 10", latitude: 0, longitude: 0),
            isSelected: false
        ) {}
    }
    .padding()
}
