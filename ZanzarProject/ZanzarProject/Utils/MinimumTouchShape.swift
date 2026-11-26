import SwiftUI

/// A hit area that is at least 44×44, centered on the view. The view keeps its look and its layout; only the
/// area that answers to a touch grows, so a small control is easy to hit without a change of design.
struct MinimumTouchShape: Shape {
    nonisolated static let minimumLength: CGFloat = 44

    func path(in rect: CGRect) -> Path {
        Path(Self.touchRect(for: rect))
    }

    nonisolated static func touchRect(for rect: CGRect) -> CGRect {
        let width = max(rect.width, minimumLength)
        let height = max(rect.height, minimumLength)
        return CGRect(x: rect.midX - width / 2, y: rect.midY - height / 2, width: width, height: height)
    }
}

extension Shape where Self == MinimumTouchShape {
    static var minimumTouch: MinimumTouchShape { MinimumTouchShape() }
}
