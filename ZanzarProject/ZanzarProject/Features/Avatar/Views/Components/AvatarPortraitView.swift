import SwiftUI

/// The avatar's face framed by a circle filled with its background color.
struct AvatarPortraitView: View {
    let avatar: Avatar
    var fallbackBackground: Color = Color(.secondarySystemFill)

    var body: some View {
        Circle()
            .fill(Color(hex: avatar.background) ?? fallbackBackground)
            .overlay {
                AvatarFaceView(avatar: avatar)
            }
            .aspectRatio(1, contentMode: .fit)
    }
}

#Preview {
    AvatarPortraitView(avatar: .placeholder)
        .padding()
}
