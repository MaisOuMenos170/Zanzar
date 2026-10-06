import SwiftUI

struct PlaceDetailNearbyPlaceCard: View {
    let place: PlaceDetailNearbyPlace
    let mediaPolicy: PlaceMediaAccessPolicy
    let onTap: () -> Void

    @ScaledMetric(relativeTo: .caption) private var cardWidth = 117
    @ScaledMetric(relativeTo: .caption) private var imageHeight = 114
    @ScaledMetric(relativeTo: .caption) private var reactionSize = 16

    private var sealState: PlaceCategorySealState {
        place.hasCheckedIn ? .earned : .preview
    }

    private var checkInsText: String {
        String(localized: "placeDetail.nearbyPlace.checkInsCount \(place.checkInCount)")
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                PlaceRemoteImage(photoReference: place.photoReference, mediaPolicy: mediaPolicy) {
                    ZStack {
                        LinearGradient(
                            colors: [Color("PlaceDetailTagGreenBackground"), Color("PlaceDetailStatsBackground")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )

                        PlaceCategorySealView(
                            category: place.category,
                            state: sealState,
                            size: 32
                        )
                    }
                }
                .frame(height: imageHeight)
                .frame(maxWidth: .infinity)

                VStack(alignment: .trailing, spacing: 8) {
                    VStack(alignment: .trailing, spacing: 0) {
                        Text(place.displayName)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Color("PlaceDetailNearbyTitle"))
                            .lineLimit(1)

                        Text(checkInsText)
                        .font(.caption2)
                        .foregroundStyle(Color("PlaceDetailNearbySubtitle"))
                    }

                    HStack(spacing: 2) {
                        ForEach(place.reactionImageNames, id: \.self) { imageName in
                            Image(imageName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: reactionSize, height: reactionSize)
                        }
                    }
                    .frame(height: reactionSize)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .background(Color("PlaceDetailNearbyCardBackground"))
            }
            .clipShape(.rect(cornerRadius: 8))
            .shadow(color: .black.opacity(0.25), radius: 1, x: 1, y: 1)
            .frame(width: cardWidth)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("placeDetail.nearbyPlace.accessibilityLabel \(place.displayName) \(checkInsText)"))
    }
}
