import SwiftUI

/// One of the user's own photos, opened over the dimmed list it came from.
struct UserPhotoViewerView: View {
    let photo: UserPhoto

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            // A tap outside the photo closes it.
            Color.clear
                .contentShape(.rect)
                .onTapGesture { dismiss() }
                .accessibilityHidden(true)

            AsyncImage(url: photo.viewerURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        .accessibilityLabel(photoTitle)
                case .failure:
                    unavailable
                case .empty:
                    if photo.viewerURL == nil {
                        unavailable
                    } else {
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: 258)
                    }
                @unknown default:
                    unavailable
                }
            }
            .frame(maxWidth: 350)
            .background(Color.brandNeutral100)
            .clipShape(.rect(cornerRadius: 8))
            .shadow(color: .black.opacity(0.25), radius: 8, y: 1)
            .overlay(alignment: .topTrailing) {
                Button {
                    dismiss()
                } label: {
                    Label("userPhotos.viewer.closeButton.title", systemImage: "xmark")
                        .labelStyle(.iconOnly)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.primary)
                        .frame(width: 30, height: 30)
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .padding(8)
            }
            .padding(.horizontal, 22)
        }
        .presentationBackground(Color.black.opacity(0.35))
    }

    private var photoTitle: String {
        photo.placeName ?? L10n.string("userPhotos.myPhotos.unknownPlace")
    }

    private var unavailable: some View {
        ContentUnavailableView(
            "userPhotos.viewer.error.title",
            systemImage: "photo.badge.exclamationmark",
            description: Text("userPhotos.viewer.error.message")
        )
        .frame(maxWidth: .infinity, minHeight: 258)
    }
}
