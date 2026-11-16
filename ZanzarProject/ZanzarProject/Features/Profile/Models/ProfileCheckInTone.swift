import SwiftUI

/// The four card colors the check-in cards rotate through.
enum ProfileCheckInTone: CaseIterable {
    case sand
    case periwinkle
    case lavender
    case gold

    static func tone(at index: Int) -> ProfileCheckInTone {
        allCases[index % allCases.count]
    }

    var background: Color {
        switch self {
        case .sand: .brandYellow300
        case .periwinkle: .brandPurple300
        case .lavender: .brandPurple150
        case .gold: .brandYellow500
        }
    }

    /// The color of the chevron in the white pill.
    var accent: Color {
        switch self {
        case .sand, .gold: .brandOrange400
        case .periwinkle, .lavender: .brandPurple500
        }
    }

    var isWarm: Bool {
        self == .sand || self == .gold
    }
}
