import SwiftUI

struct ProfileCheckInCard: View {
    let checkIn: ProfileCheckIn
    let mediaPolicy: PlaceMediaAccessPolicy

    @ScaledMetric(relativeTo: .caption) private var photoHeight: CGFloat = 78
    @ScaledMetric(relativeTo: .caption) private var reactionSize: CGFloat = 36
    @ScaledMetric(relativeTo: .caption) private var sealSize: CGFloat = 47

    var body: some View {
        VStack(spacing: 10) {
            Color("ProfileReactionPlaceholder")
                .frame(height: photoHeight)
                .overlay {
                    PlaceRemoteImage(photoURL: checkIn.photoURL, mediaPolicy: mediaPolicy) {
                        Color("ProfileReactionPlaceholder")
                    }
                }
                .overlay(alignment: .bottomLeading) {
                    if let impressionTag = checkIn.impressionTag {
                        Image(impressionTag.imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: reactionSize, height: reactionSize)
                            .padding(8)
                            .accessibilityLabel(Text("profile.checkInCard.reactionAccessibilityLabel"))
                    }
                }
                .clipped()

            AdaptiveStack(horizontalAlignment: .leading, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    placeNameText
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text("profile.checkInCard.dateLabel \(checkIn.date.formatted(date: .numeric, time: .omitted))")
                        .font(.caption)
                        .foregroundStyle(Color("PlaceDetailNearbySubtitle"))
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                sealBadge
            }
            .padding(.horizontal, 12)
        }
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity)
        .background(Color("ProfileCheckInCardBackground"))
        .clipShape(.rect(cornerRadius: 8))
        .accessibilityElement(children: .combine)
    }

    private var placeNameText: Text {
        if let placeName = checkIn.placeName {
            Text(placeName)
        } else {
            Text("profile.checkInCard.unknownPlace")
        }
    }

    @ViewBuilder
    private var sealBadge: some View {
        if let sealCategory = checkIn.sealCategory {
            PlaceCategorySealView(category: sealCategory, size: sealSize)
        } else {
            Circle()
                .fill(Color("ProfileReactionPlaceholder"))
                .frame(width: sealSize, height: sealSize)
        }
    }
}
