import SwiftUI

struct MyPhotoRow: View {
    let photo: UserPhoto

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            AsyncImage(url: photo.thumbnailURL) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Image(systemName: "photo")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.quaternary)
            }
            .frame(width: 72, height: 72)
            .clipShape(.rect(cornerRadius: 10))
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                Text(photo.placeName ?? L10n.string("userPhotos.myPhotos.unknownPlace"))
                    .font(.headline)
                    .lineLimit(2)
                UserPhotoStatusBadge(status: photo.status)
                if let reason = photo.decisionReason, photo.status == .rejected || photo.status == .removed {
                    Text(LocalizedStringKey(reason.messageKey))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Text(photo.createdAt, format: .dateTime.day().month().year())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
