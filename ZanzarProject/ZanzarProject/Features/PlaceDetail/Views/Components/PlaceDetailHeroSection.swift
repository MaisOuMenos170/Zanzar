import SwiftUI

struct PlaceDetailHeroSection: View {
    let photoReference: String?
    let tags: [PlaceDetailTag]
    let mediaPolicy: PlaceMediaAccessPolicy

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            PlaceDetailHeroImage(
                photoReference: photoReference,
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
