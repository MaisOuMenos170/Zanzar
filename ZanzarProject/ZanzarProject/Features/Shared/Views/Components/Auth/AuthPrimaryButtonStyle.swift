import SwiftUI

struct AuthPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body)
            .bold()
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color("WelcomePrimary"), in: .capsule)
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}
