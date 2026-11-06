import CoreGraphics

/// Where each hair image sits on the face canvas (397×297, same space as the other layers in `AvatarFaceView`).
///
/// Every hair has its own shape, so it has its own origin and width. The Figma file only has each hair drawn
/// together with a grey head outline (the picker thumbnails in `Avatar/CabelosMiniatura`). The images in
/// `Avatar/Cabelos` (in front of the face) and `Avatar/CabelosFundo` (behind it, only for hairs that have a part
/// there) are those thumbnails with the outline removed. Each placement scales the thumbnail so its head outline
/// lands exactly on the head of `Avatar/Pele`.
nonisolated enum AvatarHairLayout {
    struct Placement {
        /// Top-left corner and width of the `Avatar/Cabelos` image, drawn in front of the face (the height follows
        /// the image).
        let origin: CGPoint
        let width: CGFloat
        /// The `Avatar/CabelosFundo` image, drawn behind the face; `nil` when the hair has no back part.
        let back: (origin: CGPoint, width: CGFloat)?

        /// A hair whose front and back images come from the same thumbnail, so they share one frame.
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
        // The front image was redrawn at the canvas scale (1 unit = 1 canvas point), already as wide as the head needs,
        // with its fringe centered on the head. The braids are still the back image cut from the thumbnail.
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
