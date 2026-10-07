import SwiftUI

struct ActiveItineraryProgressCard: View {
    let activeItinerary: ActiveItinerary?
    let onViewDetails: (String) -> Void
    let onAbandon: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("itinerary.activeCard.title")
                .font(.body.bold())

            if let activeItinerary {
                activeContent(for: activeItinerary)
            } else {
                Text("itinerary.activeCard.empty")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color("PlaceDetailStatsBackground"))
        .clipShape(.rect(cornerRadius: 12))
    }

    @ViewBuilder
    private func activeContent(for activeItinerary: ActiveItinerary) -> some View {
        ScrollView(.horizontal) {
            HStack(spacing: 12) {
                ForEach(activeItinerary.places) { slot in
                    ItineraryProgressSlotView(slot: slot)
                }
            }
        }
        .scrollIndicators(.hidden)

        Text(activeItinerary.name)
            .font(.subheadline.bold())

        HStack {
            Button("itinerary.activeCard.viewDetails") {
                onViewDetails(activeItinerary.slug)
            }
            .buttonStyle(.bordered)

            Button("itinerary.activeCard.abandon", role: .destructive, action: onAbandon)
                .buttonStyle(.bordered)
        }
    }
}

private struct ItineraryProgressSlotView: View {
    let slot: ItinerarySlot

    var body: some View {
        Group {
            if slot.isCompleted {
                ItineraryStampView(state: .earned, size: 48)
            } else {
                ZStack {
                    Circle()
                        .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [4, 4]))
                        .foregroundStyle(.secondary)
                        .frame(width: 48, height: 48)

                    Text("?")
                        .font(.title3.bold())
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(width: 48, height: 48)
        .accessibilityLabel(
            slot.isCompleted
                ? String(localized: "itinerary.activeCard.slot.completed")
                : String(localized: "itinerary.activeCard.slot.pending")
        )
    }
}

#Preview("With route") {
    ActiveItineraryProgressCard(
        activeItinerary: ActiveItinerary(
            templateID: "1",
            slug: "centro-historico",
            name: "Centro Histórico",
            description: "",
            category: "historic",
            routeType: .fixed,
            objectives: [],
            targetCategory: nil,
            targetCount: nil,
            startedAt: .now,
            places: [
                ItinerarySlot(id: "1", placeID: "a", placeName: "Paço", isCompleted: true, completedAt: .now, stampID: nil),
                ItinerarySlot(id: "2", placeID: "b", placeName: "Museu", isCompleted: false, completedAt: nil, stampID: nil)
            ]
        ),
        onViewDetails: { _ in },
        onAbandon: {}
    )
    .padding()
}

#Preview("Empty") {
    ActiveItineraryProgressCard(activeItinerary: nil, onViewDetails: { _ in }, onAbandon: {})
        .padding()
}
