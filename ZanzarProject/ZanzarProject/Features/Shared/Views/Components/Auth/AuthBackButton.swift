import SwiftUI

struct AuthBackButton: View {
    let action: () -> Void

    var body: some View {
        Button("auth.backButton.accessibilityLabel", systemImage: "chevron.left", action: action)
            .labelStyle(.iconOnly)
            .font(.body.weight(.semibold))
            .foregroundStyle(.primary)
            .frame(width: 44, height: 44)
            .background(Color("WelcomeSecondaryBackground"), in: .circle)
    }
}
