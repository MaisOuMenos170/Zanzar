import Foundation

enum ImpressionTag: String, CaseIterable, Sendable {
    case delighted
    case happy
    case nauseated
    case sad
    case sleepy

    var imageName: String {
        switch self {
        case .delighted:
            "CarinhaSorrindo"
        case .happy:
            "CarinhaFeliz"
        case .nauseated:
            "CarinhaVomito"
        case .sad:
            "CarinhaChoro"
        case .sleepy:
            "CarinhaBocejando"
        }
    }

    static func reactions(from counts: [String: Int], selectedTag: String?) -> [PlaceDetailReaction] {
        allCases.map { tag in
            PlaceDetailReaction(
                id: tag.rawValue,
                impressionTag: tag.rawValue,
                imageName: tag.imageName,
                count: counts[tag.rawValue, default: 0],
                isSelected: tag.rawValue == selectedTag
            )
        }
    }

    static func topReactionImageNames(from counts: [String: Int], limit: Int = 5) -> [String] {
        allCases
            .sorted { counts[$0.rawValue, default: 0] > counts[$1.rawValue, default: 0] }
            .prefix(limit)
            .map(\.imageName)
    }

    static var allReactionImageNames: [String] {
        allCases.map(\.imageName)
    }
}
