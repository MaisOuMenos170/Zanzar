import SwiftUI

struct AppTypographyModifier: ViewModifier {
    let style: AppTypography
    @ScaledMetric private var size: CGFloat

    init(style: AppTypography) {
        self.style = style
        _size = ScaledMetric(wrappedValue: style.size, relativeTo: style.relativeStyle)
    }

    func body(content: Content) -> some View {
        content
            .font(.system(size: size, weight: style.weight, design: style.design))
            .tracking(style.tracking)
    }
}
