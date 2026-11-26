import SwiftUI
import TipKit

extension View {
    /// Shows `tip` in the layout, right above this view. A popover would sit on top of the controls around it and
    /// swallow the first tap outside it; this one pushes the content down instead and takes no room when there is
    /// no tip to show.
    func tipAbove<T: Tip>(_ tip: T) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            TipView(tip, arrowEdge: nil)
            self
        }
    }
}
