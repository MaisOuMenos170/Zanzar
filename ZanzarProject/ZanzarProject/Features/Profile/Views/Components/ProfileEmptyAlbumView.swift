import SwiftUI

/// A profile with no check-ins yet: the mascot, a line that invites the first one, and the way to the map
/// (Figma "G2 · Perfil vazio"). It takes the place of the empty tiles and sections.
struct ProfileEmptyAlbumView: View {
    let onExploreMap: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            MascotView(.sleepy)

            VStack(spacing: 8) {
                Text("profile.emptyAlbum.title")
                    .typography(.headline5)
                    .foregroundStyle(Color.brandNeutral950)
                    .accessibilityAddTraits(.isHeader)
                Text("profile.emptyAlbum.message")
                    .typography(.body2)
                    .foregroundStyle(Color.brandNeutral600)
            }
            .multilineTextAlignment(.center)

            Button("profile.emptyAlbum.exploreButton", action: onExploreMap)
                .buttonStyle(AuthPrimaryButtonStyle(background: .brandPurple500))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
}

#Preview {
    ProfileEmptyAlbumView {}
        .padding()
        .background(Color.profileBackground)
}
