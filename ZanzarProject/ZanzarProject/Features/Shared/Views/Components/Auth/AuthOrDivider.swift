import SwiftUI

/// Horizontal rule with a centered "ou" label, separating the primary action from Sign in with Apple.
struct AuthOrDivider: View {
    var body: some View {
        HStack(spacing: 16) {
            line
            Text("auth.or.label")
                .font(.subheadline)
                .foregroundStyle(Color.brandNeutral950)
            line
        }
        .accessibilityElement(children: .combine)
    }

    private var line: some View {
        Rectangle()
            .fill(Color.brandBlue500.opacity(0.15))
            .frame(height: 1)
    }
}

#Preview {
    AuthOrDivider()
        .padding()
        .background(Color.brandBlue50)
}
