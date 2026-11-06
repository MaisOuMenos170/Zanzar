import Foundation

/// The options offered by the avatar editor for each layer, matching the images in the asset catalog.
nonisolated enum AvatarCatalog {
    static let skinCount = 8
    static let hairCount = 7

    /// Swatch colors from the design, in the same order as `Avatar/Olhos`, `Avatar/Sobrancelhas` and `Avatar/Cilios`.
    static let eyeColors = ["#643F3B", "#543431", "#1F1E1E", "#0F6C59", "#6E0777", "#1B465D"]
    static let eyebrowColors = ["#5B4024", "#2C1617", "#38D37B", "#B240CB", "#4F65B9"]
    static let eyelashColors = ["#432F19", "#2C1617", "#38C27B", "#B240CB", "#485DB3"]
}
