import SwiftUI

struct ProfileCheckInCard: View {
    let checkIn: ProfileCheckIn

    var body: some View {
        VStack(spacing: 10) {
            Color.clear
                .frame(height: 78)
                .overlay {
                    Image("ProfileCheckInSample")
                        .resizable()
                        .scaledToFill()
                }
                .clipped()

            VStack(alignment: .leading, spacing: 4) {
                Text(checkIn.placeName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.black)
                Text("profile.checkInCard.dateLabel \(checkIn.date.formatted(date: .numeric, time: .omitted))")
                    .font(.caption2)
                    .foregroundStyle(Color("PlaceDetailNearbySubtitle"))
                Image(checkIn.impressionImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 23)
                    .accessibilityHidden(true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
        }
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity)
        .background(Color("ProfileCheckInCardBackground"))
        .overlay(alignment: .bottomTrailing) {
            reactionBadge
                .padding(.trailing, 30)
                .padding(.bottom, 22)
        }
        .clipShape(.rect(cornerRadius: 8))
        .accessibilityElement(children: .combine)
    }

    private var reactionBadge: some View {
        Circle()
            .fill(Color("ProfileReactionPlaceholder"))
            .frame(width: 47, height: 47)
            .overlay {
                if let reactionImageName = checkIn.reactionImageName {
                    Image(reactionImageName)
                        .resizable()
                        .scaledToFit()
                        .padding(2)
                }
            }
    }
}

#Preview {
    HStack {
        ProfileCheckInCard(checkIn: ProfileCheckIn.samples[0])
        ProfileCheckInCard(checkIn: ProfileCheckIn.samples[1])
    }
    .padding()
}
