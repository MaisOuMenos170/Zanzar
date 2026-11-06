import Foundation

/// Ids are 1-based; `eyelash` and `hair` also accept `Avatar.none` (0) for no layer.
struct Avatar: Hashable, Sendable {
    static let none = 0
    static let defaultBackground = "#FFF9F6"

    var skin: Int
    var eyes: Int
    var eyebrow: Int
    var eyelash: Int
    var hair: Int
    /// Hex color `#RRGGBB` of the circle drawn behind the face.
    var background: String

    static let placeholder = Avatar(
        skin: 1,
        eyes: 1,
        eyebrow: 1,
        eyelash: Avatar.none,
        hair: Avatar.none,
        background: Avatar.defaultBackground
    )
}
