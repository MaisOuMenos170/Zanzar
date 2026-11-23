import SwiftUI

/// For rows, cards and tiles that were `.plain` buttons with no answer to a press: they sink a little and dim.
struct PressableButtonStyle: ButtonStyle {
    var pressedScale: CGFloat = 0.97

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? pressedScale : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .motion(Motion.toque, value: configuration.isPressed)
    }
}
