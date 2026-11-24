import SwiftUI

/// The edge of the screen a toast sits against.
enum ToastPosition: Equatable, Sendable {
    case top
    case bottom

    var alignment: Alignment {
        switch self {
        case .top: .top
        case .bottom: .bottom
        }
    }

    var edge: Edge {
        switch self {
        case .top: .top
        case .bottom: .bottom
        }
    }

    /// The point the toasts behind the front one shrink toward: the edge they sit against.
    var pileAnchor: UnitPoint {
        switch self {
        case .top: .top
        case .bottom: .bottom
        }
    }

    /// Which way the toasts behind the front one move to peek out: down from the top edge, up from the bottom one.
    var pileDirection: CGFloat {
        switch self {
        case .top: 1
        case .bottom: -1
        }
    }
}
