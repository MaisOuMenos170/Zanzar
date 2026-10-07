import SwiftUI

struct PlaceDetailNearbySection: View {
    let places: [PlaceDetailNearbyPlace]
    let mediaPolicy: PlaceMediaAccessPolicy
    let onSelect: (MapPlace) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("placeDetail.nearbySection.title")
                .font(.body.weight(.semibold))
                .foregroundStyle(.primary)

            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(places) { nearbyPlace in
                        PlaceDetailNearbyPlaceCard(
                            place: nearbyPlace,
                            mediaPolicy: mediaPolicy
                        ) {
                            onSelect(nearbyPlace.mapPlace)
                        }
                    }
                }
            }
            .scrollIndicators(.hidden)
            // Without this the scroll view clips the cards' shadows at its bounds.
            .scrollClipDisabled()
        }
    }
}
