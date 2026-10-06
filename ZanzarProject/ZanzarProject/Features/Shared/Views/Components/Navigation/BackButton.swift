import SwiftUI

/// A back button that matches the system toolbar one (glass circle with a chevron), for screens that
/// draw their own header instead of using the navigation bar.
struct BackButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label("backButton.accessibilityLabel", systemImage: "chevron.left")
                .labelStyle(.iconOnly)
                .font(.body.weight(.semibold))
                .foregroundStyle(.primary)
                .frame(width: 30, height: 30)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
    }
}

#Preview {
    BackButton {}
        .padding()
}
