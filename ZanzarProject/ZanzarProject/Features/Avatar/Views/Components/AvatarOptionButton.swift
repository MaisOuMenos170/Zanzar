import SwiftUI

/// Makes any option picture tappable and marks the chosen one with the green check.
struct AvatarOptionButton<Content: View>: View {
    let accessibilityLabel: Text
    let isSelected: Bool
    let action: () -> Void
    @ViewBuilder let content: Content

    var body: some View {
        Button(action: action) {
            content
                .overlay(alignment: .bottomTrailing) {
                    if isSelected {
                        SelectionBadge()
                            .offset(x: 4)
                    }
                }
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
