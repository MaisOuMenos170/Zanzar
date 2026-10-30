import SwiftUI

struct PlaceDetailHeroSection: View {
    let photos: [PlacePhoto]
    let placeName: String
    let tags: [PlaceDetailTag]
    let mediaPolicy: PlaceMediaAccessPolicy

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            PlaceDetailPhotoCarousel(
                photos: photos,
                placeName: placeName,
                mediaPolicy: mediaPolicy
            )

            if !tags.isEmpty {
                HStack(spacing: 8) {
                    ForEach(tags) { tag in
                        PlaceDetailTagBadge(label: tag.label, style: tag.style)
                    }
                }
            }
        }
    }
}
