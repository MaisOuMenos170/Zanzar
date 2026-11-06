import CoreGraphics

/// Where each hair image sits on the 397×297 face canvas. `Avatar/Cabelos` (front) and `Avatar/CabelosFundo`
/// (behind the face) are the picker thumbnails without the head outline, scaled so the head matches `Avatar/Pele`.
nonisolated enum AvatarHairLayout {
    struct Placement {
        let origin: CGPoint
        let width: CGFloat
        /// `nil` when the hair has no back part.
        let back: (origin: CGPoint, width: CGFloat)?

        init(origin: CGPoint, width: CGFloat, hasBackLayer: Bool) {
            self.init(origin: origin, width: width, back: hasBackLayer ? (origin, width) : nil)
        }

        init(origin: CGPoint, width: CGFloat, back: (origin: CGPoint, width: CGFloat)?) {
            self.origin = origin
            self.width = width
            self.back = back
        }
    }

    private static let placements: [Int: Placement] = [
        1: Placement(origin: CGPoint(x: 28.0, y: 35.94), width: 337.88, hasBackLayer: true),
        // The front image was redrawn at canvas scale; the braids are still the back image cut from the thumbnail.
        2: Placement(
            origin: CGPoint(x: 53.09, y: 49.6),
            width: 284,
            back: (CGPoint(x: 28.0, y: 49.6), 337.87)
        ),
        3: Placement(origin: CGPoint(x: 0.0, y: -0.35), width: 396.48, hasBackLayer: true),
        4: Placement(origin: CGPoint(x: 28.01, y: 35.2), width: 337.86, hasBackLayer: true),
        5: Placement(origin: CGPoint(x: 28.01, y: 29.58), width: 337.87, hasBackLayer: false),
        6: Placement(origin: CGPoint(x: 28.01, y: 0.21), width: 337.87, hasBackLayer: true),
        7: Placement(origin: CGPoint(x: 28.0, y: 25.24), width: 337.87, hasBackLayer: false)
    ]

    static func placement(for hair: Int) -> Placement? {
        placements[hair]
    }
}
