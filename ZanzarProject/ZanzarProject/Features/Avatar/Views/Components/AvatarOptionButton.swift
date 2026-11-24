import SwiftUI

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
                            .transition(.scale(scale: 0.5).combined(with: .opacity))
                    }
                }
                .motion(Motion.toque, value: isSelected)
                .contentShape(.rect)
        }
        .buttonStyle(PressableButtonStyle(pressedScale: 0.94))
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
