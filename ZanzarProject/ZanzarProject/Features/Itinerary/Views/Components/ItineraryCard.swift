import SwiftUI

struct ItineraryCard: View {
    let itinerary: Itinerary
    let onViewDetails: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        content
            .padding(8)
            .background(Color(.secondarySystemBackground), in: .rect(cornerRadius: 8))
            .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private var content: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 8) {
                metrics
                name(alignment: .leading)
                detailsButton
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            HStack(alignment: .top, spacing: 8) {
                metrics

                Image("ItineraryRoutePath")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: 76)
                    .accessibilityHidden(true)

                VStack(alignment: .trailing, spacing: 8) {
                    name(alignment: .trailing)
                    detailsButton
                }
                .frame(maxWidth: 120)
            }
        }
    }

    private var metrics: some View {
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
    }

    private func name(alignment: Alignment) -> some View {
        Text(itinerary.name)
            .font(.caption.weight(.medium))
            .foregroundStyle(Color("PlaceDetailNearbyTitle"))
            .multilineTextAlignment(alignment == .leading ? .leading : .trailing)
            .frame(maxWidth: .infinity, alignment: alignment)
    }

    private var detailsButton: some View {
        Button("itinerary.card.viewDetails", action: onViewDetails)
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .tint(Color("TabBarSelected"))
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
        .font(.caption)
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

#Preview("Accessibility 5") {
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
    .dynamicTypeSize(.accessibility5)
}
