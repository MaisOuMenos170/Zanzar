import SwiftUI

/// A card sliding in from, and back out to, below the bottom edge of the screen.
/// `.move(edge: .bottom)` only goes as far as the card's own height, which leaves its rounded top edge and its
/// shadow showing in the home indicator area; this one goes past that, so nothing stays behind.
struct SheetSlideTransition: Transition {
    /// Extra distance for the home indicator area and the card's shadow.
    private let extraDistance: CGFloat = 80

    func body(content: Content, phase: TransitionPhase) -> some View {
        content.visualEffect { effect, proxy in
            effect.offset(y: phase.isIdentity ? 0 : proxy.size.height + extraDistance)
        }
    }
}
