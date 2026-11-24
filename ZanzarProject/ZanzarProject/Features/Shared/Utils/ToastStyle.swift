import SwiftUI

/// Whether a toast reports something that worked or something that failed.
enum ToastStyle: Equatable, Sendable {
    case positive
    case negative

    var symbolName: String {
        switch self {
        case .positive: "checkmark"
        case .negative: "xmark"
        }
    }

    var tint: Color {
        switch self {
        case .positive: Color("UICorrect")
        case .negative: Color("UIError")
        }
    }
}
