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
    /// SF Pro Rounded Bold 24, for the name on the profile.
    case headline5
    /// SF Pro Rounded Bold 20, for section titles.
    case headline6
    /// SF Pro Rounded Semibold 16, for card titles.
    case subtitle3
    /// SF Pro Rounded Semibold 15, for the label of a stat tile.
    case subtitle4
    /// SF Pro Regular 12, for dates, counters and secondary lines.
    case caption1
    /// SF Pro Regular 11, for the line under a section title.
    case caption2
    /// SF Pro Bold 12, for chips and small buttons.
    case caption3
    /// SF Pro Regular 10 with wide tracking, for the uppercase label of a tile.
    case overline
    /// SF Pro Semibold 16 with wide tracking, for the filled buttons of the design system.
    case button
    /// SF Pro Semibold 16, for the buttons of alerts.
    case button2
    /// SF Pro Expanded Semibold 80, for the big number of a tile.
    case display1
    /// SF Pro Expanded Regular 44, for the number of a small tile.
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
        case .headline4, .headline5, .headline6, .subtitle3, .subtitle4: .rounded
        default: .default
        }
    }

    /// `.expanded` for the big numbers; `nil` keeps the font's default width.
    var width: Font.Width? {
        switch self {
        case .display1, .display2: .expanded
        default: nil
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
