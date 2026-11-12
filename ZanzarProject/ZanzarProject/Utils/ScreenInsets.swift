import UIKit

/// Safe-area insets of the app's window, for layouts that must be placed relative to the screen edge (the tab bar
/// and the suggestion card float a fixed distance from it) and cannot read them from a view that adds an inset itself.
enum ScreenInsets {
    static var bottom: CGFloat {
        let window = UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .first
        return window?.safeAreaInsets.bottom ?? 0
    }
}
