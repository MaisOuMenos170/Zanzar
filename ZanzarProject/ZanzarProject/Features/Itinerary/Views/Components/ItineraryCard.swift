import SwiftUI

struct ItineraryCard: View {
    let itinerary: Itinerary
    let onViewDetails: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(itinerary.name)
                .font(.headline)
                .foregroundStyle(.primary)

            VStack(alignment: .leading, spacing: 4) {
                Text("itinerary.card.placesCount \(itinerary.placesCount)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text("itinerary.card.completedCount \(itinerary.completedCount)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Button("itinerary.card.viewDetails", action: onViewDetails)
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color("PlaceDetailNearbyCardBackground"))
        .clipShape(.rect(cornerRadius: 12))
    }
}

#Preview {
    ItineraryCard(
        itinerary: Itinerary(
            slug: "centro-historico",
            name: "Centro Histórico",
            category: "historic",
            routeType: .fixed,
            placesCount: 5,
            completedCount: 42,
            coverImageURL: nil
        ),
        onViewDetails: {}
    )
    .padding()
}
