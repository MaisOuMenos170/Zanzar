import SwiftUI

struct ActiveItineraryProgressCard: View {
    let activeItinerary: ActiveItinerary
    let onViewDetails: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var isStacked: Bool {
        dynamicTypeSize.isAccessibilitySize
    }

    var body: some View {
        AdaptiveStack(horizontalAlignment: .leading, spacing: 8) {
            ItineraryStampTrack(slots: activeItinerary.places.map { slot in
                ItineraryStampTrack.Slot(id: slot.id, isEarned: slot.isCompleted)
            })
            .frame(maxWidth: .infinity)

            VStack(alignment: isStacked ? .leading : .trailing, spacing: 8) {
                Text(activeItinerary.name)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color("PlaceDetailNearbyTitle"))
                    .multilineTextAlignment(isStacked ? .leading : .trailing)

                Button("itinerary.activeCard.viewDetails", action: onViewDetails)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .tint(Color("TabBarSelected"))
            }
            .frame(maxWidth: isStacked ? .infinity : 110, alignment: isStacked ? .leading : .trailing)
        }
        .padding(8)
        .background(Color("ItineraryProgressBackground"), in: .rect(cornerRadius: 8))
    }
}

#Preview {
    ActiveItineraryProgressCard(
        activeItinerary: ActiveItinerary(
            templateID: "1",
            slug: "visitando-parques",
            name: "Visitando parques",
            description: "",
            category: "park",
            routeType: .free,
            objectives: [],
            targetCategory: .park,
            targetCount: 4,
            startedAt: .now,
            places: [
                ItinerarySlot(
                    id: "1",
                    placeID: "a",
                    placeName: "Barigui",
                    isCompleted: true,
                    completedAt: .now,
                    stampID: nil
                ),
                ItinerarySlot(
                    id: "2",
                    placeID: nil,
                    placeName: nil,
                    isCompleted: false,
                    completedAt: nil,
                    stampID: nil
                ),
                ItinerarySlot(
                    id: "3",
                    placeID: nil,
                    placeName: nil,
                    isCompleted: false,
                    completedAt: nil,
                    stampID: nil
                ),
                ItinerarySlot(
                    id: "4",
                    placeID: nil,
                    placeName: nil,
                    isCompleted: false,
                    completedAt: nil,
                    stampID: nil
                )
            ]
        ),
        onViewDetails: {}
    )
    .padding()
}
