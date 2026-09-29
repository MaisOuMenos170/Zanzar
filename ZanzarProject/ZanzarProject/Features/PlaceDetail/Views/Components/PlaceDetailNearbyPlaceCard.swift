import SwiftUI

struct PlaceDetailNearbyPlaceCard: View {
    let place: PlaceDetailNearbyPlace

    var body: some View {
        VStack(spacing: 0) {
            PlaceDetailNearbyPlaceImage()

            VStack(alignment: .trailing, spacing: 8) {
                VStack(alignment: .trailing, spacing: 0) {
                    Text(place.name)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color("PlaceDetailNearbyTitle"))

                    Text(
                        String(
                            format: String(localized: "placeDetail.nearbyPlace.checkInsFormat"),
                            locale: Locale.current,
                            place.checkInCount
                        )
                    )
                    .font(.caption2)
                    .foregroundStyle(Color("PlaceDetailNearbySubtitle"))
                }

                HStack(spacing: 2) {
                    ForEach(place.reactionImageNames, id: \.self) { imageName in
                        Image(imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .background(Color("PlaceDetailNearbyCardBackground"))
        }
        .clipShape(.rect(cornerRadius: 8))
        .shadow(color: .black.opacity(0.25), radius: 1, x: 1, y: 1)
        .frame(width: 117)
    }
}

private struct PlaceDetailNearbyPlaceImage: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color("PlaceDetailTagGreenBackground"), Color("PlaceDetailStatsBackground")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Image(systemName: "leaf.fill")
                .font(.largeTitle)
                .foregroundStyle(Color("PlaceDetailTagGreen").opacity(0.6))
        }
        .frame(height: 114)
    }
}
