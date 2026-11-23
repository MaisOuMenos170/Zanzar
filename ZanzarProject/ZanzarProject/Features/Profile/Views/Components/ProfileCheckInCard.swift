import SwiftUI

struct ProfileCheckInCard: View {
    enum Layout {
        case compact
        case wide
    }

    let checkIn: ProfileCheckIn
    let tone: ProfileCheckInTone
    var layout: Layout = .compact

    @ScaledMetric(relativeTo: .body) private var minHeight: CGFloat = 124

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    placeNameText
                        .typography(.subtitle3)
                        .foregroundStyle(Color.brandNeutral950)
                        .lineLimit(1)
                    Text(checkIn.date.formatted(date: .numeric, time: .omitted))
                        .typography(.caption1)
                        .foregroundStyle(Color.brandNeutral950)
                        .lineLimit(1)
                }

                Image(systemName: "chevron.right")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(tone.accent)
                    .frame(width: 58, height: 39)
                    .background(Color.brandNeutral50, in: .capsule)
                    .accessibilityHidden(true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if layout == .wide {
                wideDecoration
                    // The seal sits 11pt from the top and 16pt from the side, closer than the card's padding.
                    .padding(.top, -5)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: minHeight, alignment: .leading)
        .background {
            tone.background
                .overlay { stripes }
        }
        .overlay(alignment: .bottomTrailing) {
            if layout == .compact {
                seal(size: 83)
                    .offset(x: 9, y: 14)
            }
        }
        .clipShape(.rect(cornerRadius: 16))
        .accessibilityElement(children: .combine)
    }

    private var stripes: DiagonalStripes {
        tone.isWarm ? .warmCard : .coolCard
    }

    private var placeNameText: Text {
        if let placeName = checkIn.placeName {
            Text(placeName)
        } else {
            Text("profile.checkInCard.unknownPlace")
        }
    }

    private var wideDecoration: some View {
        HStack(spacing: 16) {
            if let impressionTag = checkIn.impressionTag {
                Image(impressionTag.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 66)
                    .accessibilityLabel(Text("profile.checkInCard.reactionAccessibilityLabel"))
            }
            seal(size: 101)
        }
    }

    @ViewBuilder
    private func seal(size: CGFloat) -> some View {
        if let category = checkIn.sealCategory {
            PlaceCategorySealView(category: category, size: size)
        } else {
            Circle()
                .fill(Color.brandNeutral50.opacity(0.4))
                .frame(width: size, height: size)
                .accessibilityHidden(true)
        }
    }
}

#if DEBUG
#Preview {
    VStack {
        ProfileCheckInCard(checkIn: Profile.preview.recentCheckIns[0], tone: .sand)
        ProfileCheckInCard(checkIn: Profile.preview.recentCheckIns[1], tone: .periwinkle, layout: .wide)
    }
    .padding()
    .background(Color.profileBackground)
}
#endif
