import SwiftUI

/// A system font of a fixed design size that still grows with Dynamic Type. At the default text size it is exactly
/// `size`, so swapping `.font(.system(size:))` for `.scaledFont(size:)` changes nothing until the user asks for
/// larger text.
struct ScaledFontModifier: ViewModifier {
    let weight: Font.Weight
    let design: Font.Design
    @ScaledMetric private var size: CGFloat

    init(size: CGFloat, weight: Font.Weight, design: Font.Design) {
        self.weight = weight
        self.design = design
        _size = ScaledMetric(wrappedValue: size, relativeTo: Self.textStyle(for: size))
    }

    func body(content: Content) -> some View {
        content.font(.system(size: size, weight: weight, design: design))
    }

    /// The text style whose growth curve is closest to a text of this size.
    nonisolated static func textStyle(for size: CGFloat) -> Font.TextStyle {
        switch size {
        case ..<11.5: .caption2
        case ..<12.5: .caption
        case ..<14.5: .footnote
        case ..<15.5: .subheadline
        case ..<16.5: .callout
        case ..<19: .body
        case ..<21: .title3
        case ..<25: .title2
        case ..<30: .title
        default: .largeTitle
        }
    }
}

extension View {
    func scaledFont(size: CGFloat, weight: Font.Weight = .regular, design: Font.Design = .default) -> some View {
        modifier(ScaledFontModifier(size: size, weight: weight, design: design))
    }
}
