import SwiftUI

/// The photos of a place side by side, with the edge of the next one showing so it reads as scrollable.
/// A single photo (or none) looks like the plain hero image.
struct PlaceDetailPhotoCarousel: View {
    let photos: [PlacePhoto]
    let placeName: String
    let mediaPolicy: PlaceMediaAccessPolicy

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let photoWidthFraction = 0.85
    private static let photoSpacing: CGFloat = 8

    var body: some View {
        if photos.count > 1 {
            carousel
        } else {
            PlaceDetailHeroImage(photo: photos.first, mediaPolicy: mediaPolicy)
        }
    }

    private var carousel: some View {
        // Read here: the scroll transition closure is not main-actor isolated.
        let stepsBack = !reduceMotion
        return ScrollView(.horizontal) {
            // At most `PlaceDetail.maximumPhotoCount` photos from free URLs, so there is no need for a lazy stack.
            HStack(spacing: Self.photoSpacing) {
                ForEach(photos.enumerated(), id: \.offset) { index, photo in
                    PlaceDetailHeroImage(
                        photo: photo,
                        mediaPolicy: mediaPolicy,
                        accessibilityLabel: accessibilityLabel(forPhotoAt: index)
                    )
                    .containerRelativeFrame(.horizontal) { width, _ in
                        width * Self.photoWidthFraction
                    }
                    // The photo in view is the one in focus; its neighbours step back.
                    .scrollTransition(axis: .horizontal) { content, phase in
                        content
                            .scaleEffect(phase.isIdentity || !stepsBack ? 1 : 0.94)
                            .opacity(phase.isIdentity || !stepsBack ? 1 : 0.7)
                    }
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollIndicators(.hidden)
        .scrollClipDisabled()
    }

    private func accessibilityLabel(forPhotoAt index: Int) -> String {
        L10n.string("placeDetail.photo.accessibilityLabel", index + 1, photos.count, placeName)
    }
}
