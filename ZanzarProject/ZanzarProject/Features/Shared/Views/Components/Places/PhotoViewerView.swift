import SwiftUI

struct PhotoViewerView: View {
    let url: URL?
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
                        .accessibilityAddTraits(.isImage)
                case .failure:
                    unavailable
                case .empty:
                    if url == nil {
                        unavailable
                    } else {
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
