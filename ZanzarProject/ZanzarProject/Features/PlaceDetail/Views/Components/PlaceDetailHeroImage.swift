import SwiftUI

struct PlaceDetailHeroImage: View {
    var body: some View {
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
        .frame(maxWidth: .infinity)
        .frame(height: 191)
        .clipShape(.rect(cornerRadius: 16))
        .accessibilityHidden(true)
    }
}
