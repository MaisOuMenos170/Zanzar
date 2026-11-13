import SwiftUI

struct AuthPrimaryButtonStyle: ButtonStyle {
    var background = Color.brandPurple500

    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .typography(.subtitle2)
            .multilineTextAlignment(.center)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(background, in: .capsule)
            .opacity(isEnabled ? (configuration.isPressed ? 0.85 : 1) : 0.5)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .motion(Motion.toque, value: configuration.isPressed)
    }
}
