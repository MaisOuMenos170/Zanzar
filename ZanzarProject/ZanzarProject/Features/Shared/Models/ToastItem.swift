import Foundation

/// One message waiting in, or showing from, the `ToastManager`.
struct ToastItem: Identifiable, Equatable, Sendable {
    let id = UUID()
    let message: String
    let style: ToastStyle
    let position: ToastPosition
    /// How long it stays before it leaves by itself.
    let duration: Duration
}
