import SwiftUI

/// A back button that matches the system toolbar one (glass circle with a chevron), for screens that
/// draw their own header instead of using the navigation bar.
struct BackButton: View {
    let action: () -> Void

    @ScaledMetric(relativeTo: .body) private var iconFrame: CGFloat = 30

    var body: some View {
        Button(action: action) {
            Label("backButton.accessibilityLabel", systemImage: "chevron.left")
                .labelStyle(.iconOnly)
                .font(.body.weight(.semibold))
                .foregroundStyle(.primary)
                // The glass style adds 7pt of padding on each side, so this renders as a 44×44pt control
                // (measured on device), which is the HIG minimum for a hit target.
                .frame(width: iconFrame, height: iconFrame)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
    }
}

#Preview {
    BackButton {}
        .padding()
}
