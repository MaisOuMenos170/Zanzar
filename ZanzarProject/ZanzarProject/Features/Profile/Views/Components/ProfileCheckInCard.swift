import SwiftUI

struct ProfileCheckInCard: View {
    let checkIn: ProfileCheckIn

    var body: some View {
        VStack(spacing: 10) {
            Color("ProfileReactionPlaceholder")
                .frame(height: 78)
                .overlay {
                    PlaceRemoteImage(photoReference: checkIn.photoReference) {
                        Color("ProfileReactionPlaceholder")
                    }
                }
                .overlay(alignment: .bottomLeading) {
                    if let impressionTag = checkIn.impressionTag {
                        Image(impressionTag.imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 36, height: 36)
                            .padding(8)
                            .accessibilityLabel(Text("profile.checkInCard.reactionAccessibilityLabel"))
                    }
                }
                .clipped()

            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    placeNameText
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text("profile.checkInCard.dateLabel \(checkIn.date.formatted(date: .numeric, time: .omitted))")
                        .font(.caption2)
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
            PlaceCategorySealView(category: sealCategory, size: 47)
        } else {
            Circle()
                .fill(Color("ProfileReactionPlaceholder"))
                .frame(width: 47, height: 47)
        }
    }
}

#Preview {
    HStack {
        ProfileCheckInCard(checkIn: Profile.preview.recentCheckIns[0])
        ProfileCheckInCard(checkIn: Profile.preview.recentCheckIns[2])
    }
    .padding()
}
