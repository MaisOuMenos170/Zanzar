import SwiftUI

/// The text styles of the design system. Each one starts at its design size and grows with Dynamic Type.
enum AppTypography {
    /// SF Pro Rounded Semibold 32, for screen titles.
    case headline4
    /// SF Pro Semibold 16, for navigation titles.
    case subtitle1
    /// SF Pro Regular 16, for text typed into fields.
    case body1
    /// SF Pro Regular 14, for labels and small copy.
    case body2
    /// SF Pro Semibold 14, for buttons and links.
    case subtitle2

    var size: CGFloat {
        switch self {
        case .headline4: 32
        case .subtitle1, .body1: 16
        case .body2, .subtitle2: 14
        }
    }

    var weight: Font.Weight {
        switch self {
        case .headline4, .subtitle1, .subtitle2: .semibold
        case .body1, .body2: .regular
        }
    }

    var design: Font.Design {
        self == .headline4 ? .rounded : .default
    }

    var tracking: CGFloat {
        switch self {
        case .headline4, .body2: 0.25
        case .subtitle1, .body1: 0.15
        case .subtitle2: 0.1
        }
    }

    /// The Dynamic Type style the size scales with.
    var relativeStyle: Font.TextStyle {
        switch self {
        case .headline4: .largeTitle
        case .subtitle1, .body1: .body
        case .body2, .subtitle2: .subheadline
        }
    }
}

extension View {
    func typography(_ style: AppTypography) -> some View {
        modifier(AppTypographyModifier(style: style))
    }
}
