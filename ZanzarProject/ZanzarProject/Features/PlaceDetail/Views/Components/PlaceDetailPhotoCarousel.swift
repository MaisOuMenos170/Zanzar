import SwiftUI

struct PlaceDetailPhotoCarousel: View {
    let photos: [PlacePhoto]
    let placeName: String
    let mediaPolicy: PlaceMediaAccessPolicy
    var height: CGFloat = 191

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var photoBeingViewed: PlacePhoto?
    @Namespace private var zoomNamespace

    /// Small enough that the next photo shows in the margin beside the card.
    private static let photoSpacing: CGFloat = 8

    var body: some View {
        Group {
            if photos.count > 1 {
                carousel
            } else if let photo = photos.first {
                openable(PlaceDetailHeroImage(photo: photo, mediaPolicy: mediaPolicy, height: height), photo: photo)
            } else {
                PlaceDetailHeroImage(photo: nil, mediaPolicy: mediaPolicy, height: height)
            }
        }
        .fullScreenCover(item: $photoBeingViewed) { photo in
            PhotoViewerView(url: photo.url, title: placeName)
                .navigationTransition(.zoom(sourceID: photo, in: zoomNamespace))
        }
    }

    private func openable(_ image: some View, photo: PlacePhoto) -> some View {
        image
            .matchedTransitionSource(id: photo, in: zoomNamespace)
            .contentShape(.rect(cornerRadius: 16))
            .onTapGesture { photoBeingViewed = photo }
            .accessibilityAddTraits(.isButton)
            .accessibilityAction(named: Text("placeDetail.photo.openAction")) { photoBeingViewed = photo }
    }

    private var carousel: some View {
        // Read here: the scroll transition closure is not main-actor isolated.
        let stepsBack = !reduceMotion
        return ScrollView(.horizontal) {
            // At most `PlaceDetail.maximumPhotoCount` photos from free URLs, so there is no need for a lazy stack.
            HStack(spacing: Self.photoSpacing) {
                ForEach(photos.enumerated(), id: \.offset) { index, photo in
                    openable(
                        PlaceDetailHeroImage(
                            photo: photo,
                            mediaPolicy: mediaPolicy,
                            accessibilityLabel: accessibilityLabel(forPhotoAt: index),
                            height: height
                        ),
                        photo: photo
                    )
                    .containerRelativeFrame(.horizontal)
                    // The photo in view is the one in focus; its neighbours fade back. They do not shrink, which
                    // would push them out of the margin where they peek.
                    .scrollTransition(axis: .horizontal) { content, phase in
                        content.opacity(phase.isIdentity || !stepsBack ? 1 : 0.7)
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
