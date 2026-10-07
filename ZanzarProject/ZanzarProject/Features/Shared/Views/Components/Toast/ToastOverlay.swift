import SwiftUI

/// Draws the toast raised through `ToastPresenter`. Attach it once, as an overlay on the app's root view:
/// it floats under the status bar, above the navigation bar, and takes no part in the content's layout.
struct ToastOverlay: View {
    @Environment(ToastPresenter.self) private var toasts
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let displayDuration = Duration.seconds(5)

    var body: some View {
        ZStack {
            if let message = toasts.message {
                ErrorBanner(message: message)
                    .padding()
                    .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.default, value: toasts.message)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
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
