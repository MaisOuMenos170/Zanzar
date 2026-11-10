import CoreGraphics

/// What the user did in the photo editor, in pixels: turn the photo clockwise, then keep this rectangle of it.
nonisolated struct PhotoEdit: Equatable, Sendable {
    /// Clockwise quarter turns, 0 to 3.
    let quarterTurns: Int
    /// In pixels of the already turned image, origin at the top left, whole numbers.
    let cropRect: CGRect
}
