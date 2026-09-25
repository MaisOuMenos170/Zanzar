import SwiftUI

struct WelcomeIllustration: View {
    var body: some View {
        ZStack {
            Image("CarinhaSorrindo")
                .resizable()
                .scaledToFit()
                .frame(width: 180, height: 180)
                .rotationEffect(.degrees(-8.85))
                .offset(x: -40, y: -30)

            Image("CarinhaFeliz")
                .resizable()
                .scaledToFit()
                .frame(width: 194, height: 174)
                .offset(x: 50, y: 40)
        }
        .frame(height: 280)
        .accessibilityHidden(true)
    }
}

#Preview {
    WelcomeIllustration()
}
