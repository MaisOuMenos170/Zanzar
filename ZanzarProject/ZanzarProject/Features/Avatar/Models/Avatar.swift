import Foundation

/// The face the user composed. Each value is the 1-based id of the local image of that layer
/// (`Avatar/Pele`, `Avatar/Olhos`, `Avatar/Sobrancelhas`, `Avatar/Cabelos` in the asset catalog).
struct Avatar: Hashable, Sendable {
    let skin: Int
    let eyes: Int
    let eyebrow: Int
    let hair: Int
    /// Hex color `#RRGGBB` of the circle drawn behind the face.
    let background: String

    static let placeholder = Avatar(skin: 1, eyes: 1, eyebrow: 1, hair: 1, background: "#FFD166")
}
