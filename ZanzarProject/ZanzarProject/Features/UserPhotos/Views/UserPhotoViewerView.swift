import SwiftUI

/// One of the user's own photos, full screen. It opens with the system's zoom out of the thumbnail
/// (`UserPhotoListCard` sets the transition) and closes with the close button or a swipe down.
struct UserPhotoViewerView: View {
    let photo: UserPhoto

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            AsyncImage(url: photo.viewerURL, transaction: Transaction(animation: Motion.suave)) { phase in
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
                    }
                @unknown default:
                    unavailable
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
            .navigationTitle(photoTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .close) { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
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
    }
}
