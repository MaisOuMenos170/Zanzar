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
}
