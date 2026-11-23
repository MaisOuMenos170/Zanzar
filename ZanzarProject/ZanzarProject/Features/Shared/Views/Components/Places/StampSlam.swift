import SwiftUI

/// The stamp coming down on the card (Figma "Stamp (animado)", node 2005:9709): it starts big and turned, lands a
/// little small and crooked, then settles. It plays each time `trigger` changes; the view is at rest otherwise.
///
/// The Figma loop spends its first 0.5 s on the button press, so the times below start at the stamp itself.
struct StampSlam: ViewModifier {
    let trigger: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Seconds from the trigger to the moment the stamp touches the card. Haptics and the card bounce sync to it.
    static let contactDelay: TimeInterval = 0.3

    private struct Values {
        var opacity = 1.0
        var scale = 1.0
        var rotation = 0.0
    }

    func body(content: Content) -> some View {
        if reduceMotion {
            content
        } else {
            content.keyframeAnimator(initialValue: Values(), trigger: trigger) { view, values in
                view
                    .opacity(values.opacity)
                    .scaleEffect(values.scale)
                    .rotationEffect(.degrees(values.rotation))
            } keyframes: { _ in
                KeyframeTrack(\.opacity) {
                    MoveKeyframe(0)
                    LinearKeyframe(1, duration: 0.12)
                }
                KeyframeTrack(\.scale) {
                    MoveKeyframe(2.4)
                    CubicKeyframe(0.9, duration: Self.contactDelay)
                    CubicKeyframe(1.06, duration: 0.15)
                    CubicKeyframe(1.0, duration: 0.15)
                }
                KeyframeTrack(\.rotation) {
                    MoveKeyframe(-20)
                    CubicKeyframe(6, duration: Self.contactDelay)
                    CubicKeyframe(0, duration: 0.3)
                }
            }
        }
    }
}

extension View {
    func stampSlam(trigger: Int) -> some View {
        modifier(StampSlam(trigger: trigger))
    }
}
