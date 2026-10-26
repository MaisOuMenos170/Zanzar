import SwiftUI

struct NearbyPlacesCarousel: View {
    let places: [PlaceDetailNearbyPlace]
    let mediaPolicy: PlaceMediaAccessPolicy
    let onSelect: (MapPlace) -> Void

    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(alignment: .top, spacing: 8) {
                ForEach(places) { place in
                    NearbyPlaceCard(place: place, mediaPolicy: mediaPolicy) {
                        onSelect(place.mapPlace)
                    }
                }
            }
        }
        .scrollIndicators(.hidden)
        // Without this the scroll view clips the cards' shadows at its bounds.
        .scrollClipDisabled()
    }
}
