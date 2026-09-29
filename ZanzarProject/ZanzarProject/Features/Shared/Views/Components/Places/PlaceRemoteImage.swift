import SwiftUI

struct PlaceRemoteImage: View {
    let photoReference: String?
    let mediaPolicy: PlaceMediaAccessPolicy
    let placeholder: AnyView

    init(
        photoReference: String?,
        mediaPolicy: PlaceMediaAccessPolicy = .shared,
        @ViewBuilder placeholder: () -> some View
    ) {
        self.photoReference = photoReference
        self.mediaPolicy = mediaPolicy
        self.placeholder = AnyView(placeholder())
    }

    var body: some View {
        Group {
            if let photoReference,
               mediaPolicy.canLoadRemoteImages,
               let url = GooglePlacesConfiguration.photoURL(reference: photoReference) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        placeholder
                    case .empty:
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    @unknown default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .clipped()
    }
}
