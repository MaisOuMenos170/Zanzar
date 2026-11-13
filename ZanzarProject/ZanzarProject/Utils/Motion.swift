import SwiftUI

/// The app's motion vocabulary. Screens ask for a curve by name instead of picking numbers,
/// so the whole app moves with one voice. The stamp is the signature; the rest is a quieter
/// version of the same language.
enum Motion {
    /// Answer to a touch: pressing, selecting.
    static let toque: Animation = .easeOut(duration: 0.15)

    /// Fades and content swaps.
    static let suave: Animation = .smooth(duration: 0.25)

    /// Things that arrive and stop: cards, sheets, pins.
    static let assentar: Animation = .smooth(duration: 0.35)

    /// The paper stamp press and its celebrations. No bounce.
    static func carimbo(duration: TimeInterval) -> Animation {
        .easeOut(duration: duration)
    }

    /// How long a stamp takes to land, by how big it is on screen.
    enum StampSize {
        case small
        case medium
        case large

        var duration: TimeInterval {
            switch self {
            case .small: 0.35
            case .medium: 0.45
            case .large: 0.62
            }
        }
    }
}

extension View {
    /// Animates `value` changes with `animation`, or not at all when Reduce Motion is on.
    func motion<V: Equatable>(_ animation: Animation, value: V) -> some View {
        modifier(MotionModifier(animation: animation, value: value))
    }
}

extension View {
    /// Fades in and rises a little once `isShown` turns on. `order` staggers siblings by 60ms each.
    /// With Reduce Motion the view just appears.
    func entrance(_ isShown: Bool, order: Int = 0) -> some View {
        opacity(isShown ? 1 : 0)
            .offset(y: isShown ? 0 : 12)
            .motion(Motion.assentar.delay(0.06 * Double(order)), value: isShown)
    }
}

private struct MotionModifier<V: Equatable>: ViewModifier {
    let animation: Animation
    let value: V

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content.animation(reduceMotion ? nil : animation, value: value)
    }
}
