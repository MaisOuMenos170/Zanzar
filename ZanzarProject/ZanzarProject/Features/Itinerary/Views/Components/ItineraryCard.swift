import SwiftUI

struct ItineraryCard: View {
    let itinerary: Itinerary
    let onViewDetails: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            HStack(spacing: 7) {
                ItineraryMetricPill(
                    systemImage: "mappin.and.ellipse",
                    value: itinerary.placesCount,
                    accessibilityLabel: Text("itinerary.card.placesCount \(itinerary.placesCount)")
                )
                ItineraryMetricPill(
                    systemImage: "figure.walk",
                    value: itinerary.completedCount,
                    accessibilityLabel: Text("itinerary.card.completedCount \(itinerary.completedCount)")
                )
            }

            Image("ItineraryRoutePath")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: 76)
                .accessibilityHidden(true)

            VStack(alignment: .trailing, spacing: 8) {
                Text(itinerary.name)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color("PlaceDetailNearbyTitle"))
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                Button("itinerary.card.viewDetails", action: onViewDetails)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .tint(Color("TabBarSelected"))
            }
            .frame(maxWidth: 120)
        }
        .padding(8)
        .background(Color(.secondarySystemBackground), in: .rect(cornerRadius: 8))
        .accessibilityElement(children: .contain)
    }
}

private struct ItineraryMetricPill: View {
    let systemImage: String
    let value: Int
    let accessibilityLabel: Text

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: systemImage)
            Text(value, format: .number)
        }
        .font(.caption2)
        .foregroundStyle(.primary)
        .padding(.horizontal, 5)
        .padding(.vertical, 3)
        .background(Color(.systemBackground), in: .capsule)
        .accessibilityLabel(accessibilityLabel)
    }
}

#Preview {
    ItineraryCard(
        itinerary: Itinerary(
            slug: "centro-historico",
            name: "Bora passear no centro histórico?",
            category: "historic",
            routeType: .fixed,
            placesCount: 4,
            completedCount: 20,
            coverImageURL: nil
        ),
        onViewDetails: {}
    )
    .padding()
}
