import SwiftUI

/// One result in the search screen of "Sugerir um lugar": a pin, the name and the address. Looks like a row of the
/// map's search results (`DiscoverSearchResultRow`) with a pin where the map shows the icon of the category:
/// Apple Maps results have no category of ours.
struct PlaceSearchResultRow: View {
    let place: SuggestedPlace
    let onTap: () -> Void

    @ScaledMetric(relativeTo: .body) private var iconDiameter: CGFloat = 40

    private var title: String {
        place.hasName ? place.title : ShortAddress.format(place.title)
    }

    /// The address, which is the title already when the place has no name.
    private var subtitle: String? {
        place.hasName ? place.address.map(ShortAddress.format) : nil
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: "mappin")
                    .scaledFont(size: 16)
                    .foregroundStyle(Color.brandPurple600)
                    .frame(width: iconDiameter, height: iconDiameter)
                    .background(Color.brandPurple50, in: .circle)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                    if let subtitle {
                        Text(subtitle)
                            .font(.footnote)
                            .foregroundStyle(Color.brandNeutral600)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 11)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    VStack(spacing: 0) {
        PlaceSearchResultRow(
            place: SuggestedPlace(
                name: "Arcádia - Sebo & Café - Vinis, Livros, Dvds, Cds",
                address: "Rua Engenheiro Ostoja Roguski, 350, Centro, Curitiba - PR, Brasil",
                latitude: -25.44,
                longitude: -49.24
            ),
            onTap: {}
        )
        Divider().padding(.leading, 68)
        PlaceSearchResultRow(
            place: SuggestedPlace(
                name: nil,
                address: "Rua Engenheiro Ostoja Roguski, 360, Curitiba - PR, Brasil",
                latitude: -25.44,
                longitude: -49.24
            ),
            onTap: {}
        )
    }
    .background(Color.brandNeutral50)
}
