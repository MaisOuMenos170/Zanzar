import SwiftUI

struct ErrorBanner: View {
    let message: String

    var body: some View {
        Label(message, systemImage: "exclamationmark.triangle.fill")
            .font(.footnote)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.regularMaterial, in: .rect(cornerRadius: 12))
            .accessibilityLabel(message)
            .accessibilityAddTraits(.isStaticText)
    }
}

#Preview {
    ErrorBanner(message: "Invalid credentials.")
}
