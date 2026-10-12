import SwiftUI

struct WelcomeIllustration: View {
    var height: CGFloat = 280

    var body: some View {
        let scale = height / 280
        ZStack {
            Image("CarinhaSorrindo")
                .resizable()
                .scaledToFit()
                .frame(width: 180 * scale, height: 180 * scale)
                .rotationEffect(.degrees(-8.85))
                .offset(x: -40 * scale, y: -30 * scale)

            Image("CarinhaFeliz")
                .resizable()
                .scaledToFit()
                .frame(width: 194 * scale, height: 174 * scale)
                .offset(x: 50 * scale, y: 40 * scale)
        }
        .frame(height: height)
        .accessibilityHidden(true)
    }
}

#Preview {
    WelcomeIllustration()
}
