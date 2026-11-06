import Foundation

/// The face the user composed. Each value is the id of the local image of that layer
/// (`Avatar/Pele`, `Avatar/Olhos`, `Avatar/Sobrancelhas`, `Avatar/Cilios`, `Avatar/Cabelos` in the asset catalog).
/// Ids are 1-based; `eyelash` and `hair` also accept `Avatar.none` (0) for "no layer".
struct Avatar: Hashable, Sendable {
    /// Value of an optional layer (eyelash, hair) that is not drawn.
    static let none = 0
    /// Circle color behind a new face, from the design.
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
