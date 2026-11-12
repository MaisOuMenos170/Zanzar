import SwiftUI

/// Floating round button under the search bar (Figma node 1939:7987) that opens "Sugerir um lugar".
struct DiscoverSuggestButton: View {
    let action: () -> Void

    @ScaledMetric(relativeTo: .body) private var diameter: CGFloat = 50
    @ScaledMetric(relativeTo: .body) private var iconSize: CGFloat = 22

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus.bubble.fill")
                .font(.system(size: iconSize))
                .foregroundStyle(Color.brandOrange600)
                .frame(width: diameter, height: diameter)
                .background(Color.brandNeutral50, in: .circle)
                .shadow(color: .black.opacity(0.25), radius: 2, y: 1)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("placeSuggestion.toolbarButton.label")
    }
}

#Preview {
    DiscoverSuggestButton {}
        .padding()
        .background(Color.gray.opacity(0.3))
}
