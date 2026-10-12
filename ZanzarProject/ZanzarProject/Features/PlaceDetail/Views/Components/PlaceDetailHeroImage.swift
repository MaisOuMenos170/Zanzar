import SwiftUI

struct PlaceDetailHeroImage: View {
    let photoReference: String?
    let mediaPolicy: PlaceMediaAccessPolicy

    var body: some View {
        PlaceRemoteImage(photoReference: photoReference, mediaPolicy: mediaPolicy) {
            ZStack {
                LinearGradient(
                    colors: [
                        Color("PlaceDetailHeroTop"),
                        Color("PlaceDetailHeroBottom")
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                Image(systemName: "photo")
                    .font(.largeTitle)
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 191)
        .clipShape(.rect(cornerRadius: 16))
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
