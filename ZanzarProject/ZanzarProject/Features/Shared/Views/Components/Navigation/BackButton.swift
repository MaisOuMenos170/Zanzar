import SwiftUI

/// A white round back button, for screens that draw their own header instead of using the navigation bar.
struct BackButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label("backButton.accessibilityLabel", systemImage: "chevron.left")
        }
        .buttonStyle(HeaderCircleButtonStyle())
    }
}

#Preview {
    BackButton {}
        .padding()
        .background(Color.profileBackground)
}
