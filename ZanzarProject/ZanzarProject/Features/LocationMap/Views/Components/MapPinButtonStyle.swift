import SwiftUI

/// Pins and clusters sink toward their tip when pressed, so a tap on the map answers right away.
struct MapPinButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1, anchor: .bottom)
            .motion(Motion.toque, value: configuration.isPressed)
    }
}
