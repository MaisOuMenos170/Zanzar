import SwiftUI

struct PlaceDetailHeroImage: View {
    let photo: PlacePhoto?
    let mediaPolicy: PlaceMediaAccessPolicy
    /// What VoiceOver says for the photo. `nil` keeps the photo out of the accessibility tree.
    var accessibilityLabel: String?

    var body: some View {
        image
            .heroAccessibility(label: accessibilityLabel)
            .overlay(alignment: .bottomLeading) {
                if let credit = photo?.credit {
                    PlacePhotoCreditView(credit: credit)
                        .padding(8)
                }
            }
    }

    private var image: some View {
        PlaceRemoteImage(photoURL: photo?.url, mediaPolicy: mediaPolicy) {
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
    }
}

private extension View {
    @ViewBuilder
    func heroAccessibility(label: String?) -> some View {
        if let label {
            accessibilityLabel(label)
                .accessibilityAddTraits(.isImage)
        } else {
            accessibilityHidden(true)
        }
    }
}
