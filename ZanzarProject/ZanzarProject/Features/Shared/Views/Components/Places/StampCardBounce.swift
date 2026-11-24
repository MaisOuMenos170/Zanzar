import SwiftUI

/// The small jolt of the card when the stamp lands on it (Figma "Group 633274", node 2005:9686): 3pt down, 1pt up,
/// then still. Plays each time `trigger` changes, starting when the stamp touches the card.
struct StampCardBounce: ViewModifier {
    let trigger: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        if reduceMotion {
            content
        } else {
            content.keyframeAnimator(initialValue: 0.0, trigger: trigger) { view, offset in
                view.offset(y: offset)
            } keyframes: { _ in
                KeyframeTrack {
                    MoveKeyframe(0)
                    LinearKeyframe(0, duration: StampSlam.contactDelay)
                    CubicKeyframe(3, duration: 0.05)
                    CubicKeyframe(-1, duration: 0.08)
                    CubicKeyframe(0, duration: 0.07)
                }
            }
        }
    }
}

extension View {
    func stampCardBounce(trigger: Int) -> some View {
        modifier(StampCardBounce(trigger: trigger))
    }
}
