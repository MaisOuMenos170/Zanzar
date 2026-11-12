import SwiftUI

/// Draws the pile of toasts of the `ToastManager`. Attach it once, as an overlay on the root view: the toasts then
/// sit against the top (or bottom) edge of the screen, over everything, instead of pushing the content around.
/// The newest is in front; the ones behind it show a thin edge, smaller and a step further from the screen edge.
struct ToastOverlay: View {
    @Environment(ToastManager.self) private var toastManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// The height of an inline navigation bar, where the back button and the other toolbar buttons sit.
    private static let navigationBarHeight: CGFloat = 44
    /// How far each toast behind the front one sits from it, and how much smaller it gets.
    private static let stepOffset: CGFloat = 10
    private static let stepScale: CGFloat = 0.05

    /// Keeps the edge the pile was on while its last toast leaves, after the manager has already cleared it.
    @State private var lastPosition = ToastPosition.top

    var body: some View {
        let position = toastManager.current?.position ?? lastPosition
        let visible = toastManager.visibleToasts

        ZStack {
            ForEach(visible.enumerated(), id: \.element.id) { index, toast in
                let depth = visible.count - 1 - index
                ToastCard(toast: toast) {
                    toastManager.dismiss(toast.id)
                } onTouchingChanged: { isTouching in
                    if isTouching {
                        toastManager.pauseTimers()
                    } else {
                        toastManager.resumeTimers()
                    }
                }
                .scaleEffect(reduceMotion ? 1 : 1 - Self.stepScale * Double(depth), anchor: position.pileAnchor)
                .offset(y: reduceMotion ? 0 : position.pileDirection * Self.stepOffset * Double(depth))
                // With reduced motion the toasts behind cannot peek out, so they wait out of sight.
                .opacity(depth == 0 || !reduceMotion ? 1 : 0)
                .zIndex(Double(index))
                .allowsHitTesting(depth == 0)
                .accessibilityHidden(depth != 0)
                .transition(reduceMotion ? .opacity : .move(edge: toast.position.edge).combined(with: .opacity))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        // The root overlay cannot see the navigation bar, so a toast at the top leaves room for its buttons.
        .padding(.top, position == .top ? Self.navigationBarHeight : 0)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: position.alignment)
        .animation(.spring(duration: 0.4, bounce: 0.15), value: visible.map(\.id))
        .onChange(of: toastManager.current?.position) { _, newPosition in
            if let newPosition {
                lastPosition = newPosition
            }
        }
    }
}
