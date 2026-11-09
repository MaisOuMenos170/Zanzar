import CoreGraphics

/// When the device warns about faces in the foreground. Vision's face boxes are tighter than the backend's
/// UltraFace boxes, so the area threshold is measured separately (docs/fotos-de-usuario-decisao.md): on the sample,
/// photos of places had no face at all, a two-person selfie measured 0.83% and a mid-shot portrait 0.21%.
nonisolated enum FacePolicy {
    /// A face covering at least 0.5% of the photo (Vision box) counts as in the foreground.
    static let prominentArea: CGFloat = 0.005
    static let crowdCount = 5

    static func prominentFaces(in faces: [CGRect]) -> [CGRect] {
        if faces.count >= crowdCount { return faces }
        return faces.filter { $0.width * $0.height >= prominentArea }
    }
}
