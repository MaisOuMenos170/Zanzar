import SwiftUI

/// The white round button of the screens that draw their own header (back, share): 44pt, the HIG minimum
/// for a hit target, on the Figma "neutral/50" fill.
struct HeaderCircleButtonStyle: ButtonStyle {
    @ScaledMetric(relativeTo: .body) private var size: CGFloat = 44

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .labelStyle(.iconOnly)
            .font(.body.weight(.semibold))
            .foregroundStyle(.primary)
            .frame(width: size, height: size)
            .background(Color.brandNeutral50, in: .circle)
            .contentShape(.circle)
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}
