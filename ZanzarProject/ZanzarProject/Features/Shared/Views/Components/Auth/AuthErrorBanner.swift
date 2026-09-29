import SwiftUI

struct AuthErrorBanner: View {
    let message: String

    var body: some View {
        Label(message, systemImage: "exclamationmark.triangle.fill")
            .font(.footnote)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.regularMaterial, in: .rect(cornerRadius: 12))
            .accessibilityLabel(message)
            .accessibilityAddTraits(.isStaticText)
    }
}

#Preview {
    AuthErrorBanner(message: "Invalid credentials.")
}
