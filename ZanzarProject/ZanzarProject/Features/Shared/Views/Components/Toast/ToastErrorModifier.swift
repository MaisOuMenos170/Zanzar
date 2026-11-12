import SwiftUI

/// Raises a toast each time `message` becomes a new value, so a screen can show what its view model reports
/// without drawing the message itself.
struct ToastErrorModifier: ViewModifier {
    let message: String?
    let style: ToastStyle
    let position: ToastPosition

    @Environment(ToastManager.self) private var toastManager

    func body(content: Content) -> some View {
        content
            .onChange(of: message) { _, newMessage in
                guard let newMessage else { return }
                toastManager.show(newMessage, style: style, position: position)
            }
    }
}

extension View {
    func toast(for message: String?, style: ToastStyle = .negative, position: ToastPosition = .top) -> some View {
        modifier(ToastErrorModifier(message: message, style: style, position: position))
    }
}
