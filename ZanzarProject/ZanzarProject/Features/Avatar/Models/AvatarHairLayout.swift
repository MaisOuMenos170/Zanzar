import CoreGraphics

/// Where each hair image sits on the face canvas (397×297, same space as the other layers in `AvatarFaceView`).
///
/// Every hair has its own shape, so it has its own origin and width. The Figma file only has each hair drawn
/// together with a grey head outline (the picker thumbnails in `Avatar/CabelosMiniatura`). The images in
/// `Avatar/Cabelos` (in front of the face) and `Avatar/CabelosFundo` (behind it, only for hairs that have a part
/// there) are those thumbnails with the outline removed. Each placement scales the thumbnail so its head outline
/// lands exactly on the head of `Avatar/Pele`.
nonisolated enum AvatarHairLayout {
    struct Placement: Equatable {
        let origin: CGPoint
        let width: CGFloat
        /// `true` when the hair also has an `Avatar/CabelosFundo` image to draw behind the face.
        let hasBackLayer: Bool
    }

    private static let placements: [Int: Placement] = [
        1: Placement(origin: CGPoint(x: 28.0, y: 35.94), width: 337.88, hasBackLayer: true),
        2: Placement(origin: CGPoint(x: 28.0, y: 49.6), width: 337.87, hasBackLayer: true),
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
