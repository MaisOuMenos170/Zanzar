import SwiftUI

/// The name of the place with how far it is and whether it is open, and "Ver rota" on the other side
/// (Figma "Título", node 2005:9646).
struct PlaceDetailTitleRow: View {
    let name: String
    let distanceText: String?
    let openingHoursText: String
    let isOpen: Bool?
    let latitude: Double
    let longitude: Double

    @ScaledMetric(relativeTo: .title2) private var titleSize: CGFloat = 22

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.system(size: titleSize, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.brandSheetTitle)
                    .accessibilityAddTraits(.isHeader)

                // Stacks when the two do not fit side by side, e.g. at accessibility text sizes.
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 8) { info }
                    VStack(alignment: .leading, spacing: 4) { info }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            PlaceDetailDirectionsButton(latitude: latitude, longitude: longitude, placeName: name)
        }
    }

    @ViewBuilder private var info: some View {
        if let distanceText {
            Text(distanceText)
                .typography(.caption1)
                .foregroundStyle(.secondary)
        }

        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
                .accessibilityHidden(true)
            Text(openingHoursText)
                .typography(.caption1)
                .foregroundStyle(Color.brandNeutral900)
                // At large text sizes it wraps to a second line; it never ends in "…".
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var statusColor: Color {
        switch isOpen {
        case true: Color("PlaceDetailOpenStatus")
        case false: Color("PlaceDetailClosedStatus")
        case nil: Color.brandNeutral600
        }
    }
}

#Preview {
    PlaceDetailTitleRow(
        name: "Jardim Botânico",
        distanceText: "a 1,3 km",
        openingHoursText: "Aberto até 18h",
        isOpen: true,
        latitude: -25.44,
        longitude: -49.24
    )
    .padding()
    .background(Color.profileBackground)
}
