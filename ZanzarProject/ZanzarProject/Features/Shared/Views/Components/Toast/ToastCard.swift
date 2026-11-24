import SwiftUI

/// A toast that can be dragged sideways: let go past a short distance, or with a quick flick, and it flies off the
/// screen and is dismissed. A shorter drag springs back.
struct ToastCard: View {
    let toast: ToastItem
    let onDismiss: () -> Void
    /// Tells the manager to hold its countdown while a finger is on the toast, and to restart it afterwards.
    let onTouchingChanged: (Bool) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    @State private var width: CGFloat = 0

    private static let dismissDistance: CGFloat = 80
    private static let dismissFlickDistance: CGFloat = 200

    var body: some View {
        ToastView(message: toast.message, style: toast.style)
            .offset(x: dragOffset)
            .opacity(fade)
            .onGeometryChange(for: CGFloat.self) { proxy in
                proxy.size.width
            } action: { newWidth in
                width = newWidth
            }
            .gesture(drag)
            .accessibilityAction(named: Text("toast.dismiss.accessibilityAction"), onDismiss)
    }

    /// The toast thins out as it leaves, so it reads as going away.
    private var fade: Double {
        guard width > 0 else { return 1 }
        return 1 - min(abs(dragOffset) / width, 1) * 0.6
    }

    private var drag: some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                if !isDragging {
                    isDragging = true
                    onTouchingChanged(true)
                }
                dragOffset = value.translation.width
            }
            .onEnded { value in
                isDragging = false
                let goesAway = abs(value.translation.width) > Self.dismissDistance
                    || abs(value.predictedEndTranslation.width) > Self.dismissFlickDistance
                if goesAway {
                    flyOff(toward: value.translation.width)
                } else {
                    withAnimation(.spring(duration: 0.3, bounce: 0.2)) {
                        dragOffset = 0
                    }
                    onTouchingChanged(false)
                }
            }
    }

    private func flyOff(toward translation: CGFloat) {
        guard !reduceMotion else {
            onDismiss()
            return
        }
        let direction: CGFloat = translation < 0 ? -1 : 1
        withAnimation(.easeOut(duration: 0.2)) {
            dragOffset = direction * (width + 32)
        } completion: {
            onDismiss()
        }
    }
}

#Preview {
    ToastCard(
        toast: ToastItem(message: "Mensagem positiva!", style: .positive, position: .top, duration: .seconds(4)),
        onDismiss: {},
        onTouchingChanged: { _ in }
    )
    .padding(16)
    .background(Color.brandBlue50)
}
