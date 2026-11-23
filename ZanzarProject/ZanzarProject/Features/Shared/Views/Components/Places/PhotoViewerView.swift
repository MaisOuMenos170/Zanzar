import SwiftUI

/// A photo on the black of a full screen viewer, with a close button: where a photo of a place, or one a user
/// sent, opens when it is tapped.
struct PhotoViewerView: View {
    /// `nil` when there is no photo to show; the viewer then says so.
    let url: URL?
    /// What the system uses as the title, and what VoiceOver reads for the photo.
    let title: String

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            AsyncImage(url: url, transaction: Transaction(animation: Motion.suave)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        .accessibilityLabel(title)
                case .failure:
                    unavailable
                case .empty:
                    if url == nil {
                        unavailable
                    } else {
                        // Light on the black of the viewer, so the wait reads as a photo on its way.
                        Color.white.opacity(0.12)
                            .shimmering()
                    }
                @unknown default:
                    unavailable
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .close) { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var unavailable: some View {
        ContentUnavailableView(
            "userPhotos.viewer.error.title",
            systemImage: "photo.badge.exclamationmark",
            description: Text("userPhotos.viewer.error.message")
        )
    }
}
