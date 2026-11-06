import CoreGraphics

/// A vector from the passport illustration, placed on the illustration's 393×640 canvas.
/// `center` is the center of the piece (not of its rotated bounds) and `rotation` is in degrees.
struct PassportArtPiece: Identifiable, Sendable {
    let name: String
    let size: CGSize
    let center: CGPoint
    let rotation: Double

    var id: String { name }

    static let cardTilt = -4.73

    static let tornPaper: [PassportArtPiece] = [
        .init("PassportTornPaperA", 149.73, 140.235, centerX: 112.2, centerY: 98.2, rotation: -18.45),
        .init("PassportTornPaperB", 149.73, 140.235, centerX: 117.21, centerY: 97.22, rotation: -18.45)
    ]

    static let cardFrame: [PassportArtPiece] = [
        .init("PassportCardFill", 322.939, 443.244, centerX: 203.75, centerY: 306.64, rotation: cardTilt),
        .init("PassportCardBorder", 328.089, 448.367, centerX: 194.75, centerY: 295.14, rotation: cardTilt)
    ]

    static let arrows = PassportArtPiece(
        name: "PassportArrows",
        size: CGSize(width: 338.402, height: 422.377),
        center: CGPoint(x: 183.495, y: 411.505),
        rotation: -3.34
    )

    static let cardDecorations: [PassportArtPiece] = [
        .init("PassportAirplane", 66.6853, 60.1264, centerX: 319.92, centerY: 459.87, rotation: cardTilt),
        .init("PassportCountPill", 137.987, 19.0663, centerX: 276.61, centerY: 441.04, rotation: cardTilt),
        .init("PassportDivider", 312.115, 1, centerX: 194.67, centerY: 296.42, rotation: cardTilt),
        .init("PassportStamp1", 48.6201, 49.0547, centerX: 169.78, centerY: 249.9, rotation: cardTilt),
        .init("PassportStamp2", 71.8876, 50.4972, centerX: 130.69, centerY: 167.12, rotation: cardTilt),
        .init("PassportStamp3", 81.9318, 55.9476, centerX: 101.96, centerY: 248.58, rotation: cardTilt),
        .init("PassportStamp4", 48.108, 43.4044, centerX: 135.88, centerY: 216.8, rotation: cardTilt),
        .init("PassportStamp5", 45.4033, 45.6491, centerX: 76.89, centerY: 197.88, rotation: cardTilt),
        .init("PassportLines", 90.5334, 30.6457, centerX: 129.51, centerY: 482.7, rotation: cardTilt),
        .init("PassportDotsA", 48.9077, 24.4135, centerX: 306.11, centerY: 252.96, rotation: cardTilt),
        .init("PassportDotsB", 48.9166, 24.4147, centerX: 255.88, centerY: 257.14, rotation: cardTilt)
    ]

    static let hand = PassportArtPiece(
        name: "PassportStampHand",
        size: CGSize(width: 256.328, height: 203.788),
        center: CGPoint(x: 319.0, y: 156.89),
        rotation: 0
    )
    static let handMotion = PassportArtPiece(
        name: "PassportStampMotion",
        size: CGSize(width: 41.7195, height: 42.8961),
        center: CGPoint(x: 177.37, y: 120.84),
        rotation: -10.31
    )
}

private extension PassportArtPiece {
    init(_ name: String, _ width: Double, _ height: Double, centerX: Double, centerY: Double, rotation: Double) {
        self.init(
            name: name,
            size: CGSize(width: width, height: height),
            center: CGPoint(x: centerX, y: centerY),
            rotation: rotation
        )
    }
}
