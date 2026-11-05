import SwiftUI

struct NearbyPlaceCard: View {
    let place: PlaceDetailNearbyPlace
    let mediaPolicy: PlaceMediaAccessPolicy
    let onTap: () -> Void

    @ScaledMetric(relativeTo: .caption) private var cardWidth = 117
    @ScaledMetric(relativeTo: .caption) private var imageHeight = 114
    @ScaledMetric(relativeTo: .caption) private var reactionSize = 16
    // The text block has a fixed height (8 + two 16 lines + 8 + 16 reactions + 8), as in the design:
    // every card is the same size no matter how long the name is or how many reactions it has.
    @ScaledMetric(relativeTo: .caption) private var textLineHeight = 16
    @ScaledMetric(relativeTo: .caption) private var infoHeight = 72

    private var sealState: PlaceCategorySealState {
        place.hasCheckedIn ? .earned : .preview
    }

    private var checkInsText: String {
        L10n.string("placeDetail.nearbyPlace.checkInsCount", place.checkInCount)
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                Color.clear
                    .frame(height: imageHeight)
                    .overlay {
                        PlaceRemoteImage(photoURL: place.photoURL, mediaPolicy: mediaPolicy) {
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
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .clipped()

                VStack(alignment: .trailing, spacing: 8) {
                    VStack(alignment: .trailing, spacing: 0) {
                        Text(place.displayName)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Color("PlaceDetailNearbyTitle"))
                            .lineLimit(1)
                            .frame(height: textLineHeight)

                        Text(checkInsText)
                            .font(.caption2)
                            .foregroundStyle(Color("PlaceDetailNearbySubtitle"))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .frame(height: textLineHeight)
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
                .frame(maxWidth: .infinity, minHeight: infoHeight, maxHeight: infoHeight, alignment: .topTrailing)
                .background(Color("PlaceDetailNearbyCardBackground"))
            }
            .frame(width: cardWidth)
            .clipShape(.rect(cornerRadius: 8))
            .shadow(color: .black.opacity(0.25), radius: 1, x: 1, y: 1)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("placeDetail.nearbyPlace.accessibilityLabel \(place.displayName) \(checkInsText)"))
    }
}
