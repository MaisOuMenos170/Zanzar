import SwiftUI

/// One of the user's photos in a list card: the thumbnail, the place, the date, where the photo stands
/// and a trash button. A photo with no thumbnail has no picture slot.
struct UserPhotoRow: View {
    let photo: UserPhoto
    let onOpen: () -> Void
    let onDelete: () -> Void

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
                        if let reason = photo.decisionReason, photo.status == .rejected || photo.status == .removed {
                            Text(LocalizedStringKey(reason.messageKey))
                                .typography(.caption1)
                                .foregroundStyle(Color.brandNeutral600)
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
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
    }
}
