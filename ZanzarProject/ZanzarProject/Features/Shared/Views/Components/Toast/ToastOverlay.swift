import SwiftUI

/// Draws the toast raised through `ToastPresenter`. Attach it once as a top safe-area inset so the
/// banner reserves space instead of covering the navigation bar and the fields under it.
struct ToastOverlay: View {
    @Environment(ToastPresenter.self) private var toasts
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let displayDuration = Duration.seconds(5)

    var body: some View {
        Group {
            if let message = toasts.message {
                ErrorBanner(message: message)
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 4)
                    .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.default, value: toasts.message)
        .frame(maxWidth: .infinity, alignment: .top)
        .allowsHitTesting(false)
        .task(id: toasts.message) {
            guard toasts.message != nil else { return }
            do {
                try await Task.sleep(for: Self.displayDuration)
            } catch {
                return
            }
            toasts.dismiss()
        }
    }
}
