import SwiftUI

struct PlaceRemoteImage<Placeholder: View>: View {
    let photoReference: String?
    let mediaPolicy: PlaceMediaAccessPolicy
    let placeholder: Placeholder

    init(
        photoReference: String?,
        mediaPolicy: PlaceMediaAccessPolicy? = nil,
        @ViewBuilder placeholder: () -> Placeholder
    ) {
        self.photoReference = photoReference
        self.mediaPolicy = mediaPolicy ?? .shared
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
                        // A fill image reports a size larger than the space it is given. As an overlay it no
                        // longer takes part in layout, so the frame stays exactly the proposed size and the
                        // overflow is only clipped.
                        Color.clear
                            .overlay {
                                image
                                    .resizable()
                                    .scaledToFill()
                            }
                            .clipped()
                    case .failure:
                        placeholder
                            .onAppear {
                                #if DEBUG
                                AppLog.placeDetail.warning("Place photo failed to load ref=\(photoReference)")
                                #endif
                            }
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
    }
}
