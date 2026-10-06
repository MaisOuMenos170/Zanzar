import SwiftUI

struct PlaceRemoteImage<Placeholder: View>: View {
    let photoReference: String?
    let mediaPolicy: PlaceMediaAccessPolicy
    let placeholder: Placeholder

    init(
        photoReference: String?,
        mediaPolicy: PlaceMediaAccessPolicy = .shared,
        @ViewBuilder placeholder: () -> Placeholder
    ) {
        self.photoReference = photoReference
        self.mediaPolicy = mediaPolicy
        self.placeholder = placeholder()
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
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .clipped()
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
