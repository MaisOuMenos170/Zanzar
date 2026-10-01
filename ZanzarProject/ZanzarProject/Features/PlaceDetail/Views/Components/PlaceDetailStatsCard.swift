import SwiftUI

struct PlaceDetailStatsCard: View {
    let totalCheckIns: Int
    let category: ZanzarPlaceCategory

    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 4) {
                Text(totalCheckIns, format: .number)
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

            PlaceCategorySealView(category: category)
                .frame(width: 102, height: 102)
        }
        .padding(.horizontal, 36)
        .padding(.vertical, 16)
        .background(Color("PlaceDetailStatsBackground"), in: .rect(cornerRadius: 16))
    }
}
