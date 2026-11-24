import SwiftUI

/// One place found by the search: its category icon, the name, and the category with the distance.
struct DiscoverSearchResultRow: View {
    let place: MapPlace
    let onTap: () -> Void

    @ScaledMetric(relativeTo: .body) private var iconDiameter: CGFloat = 40

    private var subtitle: String {
        let category = L10n.string(place.category.titleKey)
        guard let distanceText = place.roundedDistanceText else { return category }
        return "\(category) · \(distanceText)"
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: place.pinIconName)
                    .font(.system(size: 16))
                    .foregroundStyle(Color.brandPurple600)
                    .frame(width: iconDiameter, height: iconDiameter)
                    .background(Color.brandPurple50, in: .circle)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(place.displayName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(Color.brandNeutral600)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .frame(minHeight: 56)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    DiscoverSearchResultRow(
        place: MapPlace(
            id: "1",
            name: "Jardim Botânico",
            latitude: 0,
            longitude: 0,
            category: .park,
            distanceMeters: 1300
        ),
        onTap: {}
    )
}
