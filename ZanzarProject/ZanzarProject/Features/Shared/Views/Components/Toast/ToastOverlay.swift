import SwiftUI

/// Draws the toast the `ToastManager` is showing. Attach it once, as an overlay on the root view: the toast then sits
/// against the top (or bottom) edge of the screen, over everything, instead of pushing the content around.
struct ToastOverlay: View {
    @Environment(ToastManager.self) private var toastManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// The height of an inline navigation bar, where the back button and the other toolbar buttons sit.
    private static let navigationBarHeight: CGFloat = 44

    /// Keeps the edge a toast was on while it leaves, after the manager has already cleared it.
    @State private var lastPosition = ToastPosition.top

    var body: some View {
        let position = toastManager.current?.position ?? lastPosition

        ZStack {
            if let toast = toastManager.current {
                ToastCard(toast: toast) {
                    toastManager.dismiss(toast.id)
                } onTouchingChanged: { isTouching in
                    if isTouching {
                        toastManager.pauseTimer()
                    } else {
                        toastManager.resumeTimer()
                    }
                }
                .id(toast.id)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                // The root overlay cannot see the navigation bar, so a toast at the top leaves room for its buttons.
                .padding(.top, toast.position == .top ? Self.navigationBarHeight : 0)
                .transition(reduceMotion ? .opacity : .move(edge: toast.position.edge).combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: position.alignment)
        .animation(.spring(duration: 0.4, bounce: 0.15), value: toastManager.current?.id)
        .onChange(of: toastManager.current?.position) { _, newPosition in
            if let newPosition {
                lastPosition = newPosition
            }
        }
    }
}
