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

            NearbyPlacesCarousel(places: places, mediaPolicy: mediaPolicy, onSelect: onSelect)
        }
    }
}
