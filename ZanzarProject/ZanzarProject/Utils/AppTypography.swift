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
    case headline5
    case headline6
    case subtitle3
    case subtitle4
    case caption1
    case caption2
    case caption3
    case overline
    case button
    case button2
    case display1
    case display2

    var size: CGFloat {
        switch self {
        case .display1: 80
        case .display2: 44
        case .headline4: 32
        case .headline5: 24
        case .headline6: 20
        case .subtitle1, .subtitle3, .body1, .button, .button2: 16
        case .subtitle4: 15
        case .body2, .subtitle2: 14
        case .caption1, .caption3: 12
        case .caption2: 11
        case .overline: 10
        }
    }

    var weight: Font.Weight {
        switch self {
        case .headline4, .subtitle1, .subtitle2, .subtitle3, .subtitle4, .button, .button2, .display1: .semibold
        case .headline5, .headline6, .caption3: .bold
        case .body1, .body2, .caption1, .caption2, .overline, .display2: .regular
        }
    }

    var design: Font.Design {
        switch self {
        case .headline4, .headline5, .headline6, .subtitle3, .subtitle4, .display1, .display2: .rounded
        default: .default
        }
    }

    var tracking: CGFloat {
        switch self {
        case .headline4, .body2: 0.25
        case .subtitle1, .body1, .headline6, .display1, .display2: 0.15
        case .subtitle2, .subtitle3: 0.1
        case .overline, .button: 1.5
        case .headline5, .subtitle4, .caption1, .caption2, .caption3, .button2: 0
        }
    }

    /// The Dynamic Type style the size scales with.
    var relativeStyle: Font.TextStyle {
        switch self {
        case .headline4, .display1, .display2: .largeTitle
        case .headline5: .title
        case .headline6: .title3
        case .subtitle1, .subtitle3, .body1, .button, .button2: .body
        case .body2, .subtitle2, .subtitle4: .subheadline
        case .caption1, .caption3: .caption
        case .caption2, .overline: .caption2
        }
    }
}

extension View {
    func typography(_ style: AppTypography) -> some View {
        modifier(AppTypographyModifier(style: style))
    }
}
