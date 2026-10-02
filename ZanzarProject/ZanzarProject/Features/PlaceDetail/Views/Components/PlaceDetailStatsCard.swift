import SwiftUI

struct PlaceDetailStatsCard: View {
    let totalCheckIns: Int

    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 4) {
                Text(totalCheckIns, format: .number)
                    .contentTransition(.numericText(value: Double(totalCheckIns)))
                    .animation(.default, value: totalCheckIns)
                    .font(.largeTitle)
                    .bold()
                    .foregroundStyle(.primary)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)

                Text("placeDetail.statsCard.totalCheckInsLabel")
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)

            PlaceDetailBadgeIcon()
                .frame(width: 102, height: 102)
        }
        .padding(.horizontal, 36)
        .padding(.vertical, 16)
        .background(Color("PlaceDetailStatsBackground"), in: .rect(cornerRadius: 16))
    }
}

private struct PlaceDetailBadgeIcon: View {
    var body: some View {
        ZStack {
            Image(systemName: "seal.fill")
                .font(.system(size: 88))
                .foregroundStyle(Color("PlaceDetailTagGreenBackground"))
                .rotationEffect(.degrees(-8))

            Image(systemName: "seal.fill")
                .font(.system(size: 88))
                .foregroundStyle(Color("PlaceDetailTagGreen"))
                .rotationEffect(.degrees(8))

            Circle()
                .fill(Color("PlaceDetailTagGreenBackground"))
                .frame(width: 56, height: 56)

            Image(systemName: "leaf.fill")
                .font(.title)
                .foregroundStyle(Color("PlaceDetailTagGreen"))
        }
    }
}
