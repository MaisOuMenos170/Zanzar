import SwiftUI

/// One of the user's photos in a list card: the thumbnail, the place, the date, where the photo stands
/// and a trash button. A photo with no thumbnail has no picture slot.
struct UserPhotoRow: View {
    let photo: UserPhoto
    let onOpen: () -> Void
    let onDelete: () -> Void
    /// The namespace the full-screen viewer zooms out of; the thumbnail is where the zoom starts.
    var zoomNamespace: Namespace.ID?

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onOpen) {
                HStack(spacing: 12) {
                    if let thumbnailURL = photo.thumbnailURL {
                        AsyncImage(url: thumbnailURL) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            Color.brandNeutral100
                        }
                        .frame(width: 56, height: 56)
                        .clipShape(.rect(cornerRadius: 8))
                        .zoomSource(id: photo.id, in: zoomNamespace)
                        .accessibilityHidden(true)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(photo.placeName ?? L10n.string("userPhotos.myPhotos.unknownPlace"))
                            .typography(.subtitle2)
                            .foregroundStyle(Color.black)
                            .lineLimit(2)
                        HStack(spacing: 8) {
                            Text(photo.createdAt.formatted(date: .numeric, time: .omitted))
                                .typography(.caption1)
                                .foregroundStyle(Color.brandNeutral600)
                            UserPhotoStatusIndicator(status: photo.status)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityHint("userPhotos.myPhotos.openHint")

            Button(role: .destructive, action: onDelete) {
                Label("userPhotos.myPhotos.deleteButton.title", systemImage: "trash")
                    .labelStyle(.iconOnly)
                    .font(.body)
                    .foregroundStyle(Color.brandErrorRed)
                    .padding(4)
                    // The icon sits in the 4pt padding of the design; the touch area reaches the 44pt minimum.
                    .contentShape(.rect.inset(by: -8))
            }
            .buttonStyle(.plain)
        }
        .padding(12)
    }
}

private extension View {
    /// Marks this view as where the full-screen zoom of `id` starts, when there is a namespace to zoom in.
    @ViewBuilder
    func zoomSource(id: String, in namespace: Namespace.ID?) -> some View {
        if let namespace {
            matchedTransitionSource(id: id, in: namespace)
        } else {
            self
        }
    }
}
