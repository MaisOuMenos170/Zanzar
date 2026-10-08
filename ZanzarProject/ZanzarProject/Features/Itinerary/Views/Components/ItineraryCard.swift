import SwiftUI

struct ItineraryCard: View {
    let itinerary: Itinerary
    var mediaPolicy: PlaceMediaAccessPolicy = .shared
    let onViewDetails: () -> Void

    @ScaledMetric(relativeTo: .body) private var coverHeight = 120

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let coverURL {
                AsyncImage(url: coverURL) { phase in
                    switch phase {
                    case .success(let image):
                        Color.clear
                            .overlay {
                                image
                                    .resizable()
                                    .scaledToFill()
                            }
                            .clipped()
                    case .failure:
                        Color("PlaceDetailStatsBackground")
                    case .empty:
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    @unknown default:
                        Color("PlaceDetailStatsBackground")
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: coverHeight)
                .accessibilityHidden(true)
            }

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
        }
        .background(Color("PlaceDetailNearbyCardBackground"))
        .clipShape(.rect(cornerRadius: 12))
    }

    private var coverURL: URL? {
        guard mediaPolicy.canLoadRemoteImages,
              let raw = itinerary.coverImageURL else { return nil }
        return URL(string: raw)
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
