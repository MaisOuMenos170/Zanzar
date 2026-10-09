import Foundation

nonisolated enum ImpressionTag: String, CaseIterable, Sendable {
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

    /// Images of the emotions that have at least one rating, most rated first. Ties keep the
    /// declaration order of `ImpressionTag`.
    static func topReactionImageNames(from counts: [String: Int], limit: Int = 5) -> [String] {
        allCases
            .enumerated()
            .filter { counts[$0.element.rawValue, default: 0] > 0 }
            .sorted { lhs, rhs in
                let lhsCount = counts[lhs.element.rawValue, default: 0]
                let rhsCount = counts[rhs.element.rawValue, default: 0]
                return lhsCount != rhsCount ? lhsCount > rhsCount : lhs.offset < rhs.offset
            }
            .prefix(limit)
            .map(\.element.imageName)
    }
}
