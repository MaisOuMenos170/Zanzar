import CoreGraphics
import CoreImage

/// Pixelates the given face boxes. Pixelation (not a soft blur) so nothing of the face can be recovered.
nonisolated enum FaceBlurrer {
    /// How much bigger than the detected box the covered area is, so hair and chin are covered too.
    static let margin: CGFloat = 0.35

    @concurrent
    static func blur(_ faces: [CGRect], in image: CGImage) async -> CGImage? {
        let input = CIImage(cgImage: image)
        let extent = input.extent
        var output = input
        for face in faces {
            let box = CGRect(
                x: face.minX * extent.width,
                y: face.minY * extent.height,
                width: face.width * extent.width,
                height: face.height * extent.height
            )
            .insetBy(dx: -face.width * extent.width * margin, dy: -face.height * extent.height * margin)
            .intersection(extent)
            guard !box.isNull, box.width > 1, box.height > 1 else { continue }

            let pixelated = input
                .clampedToExtent()
                .applyingFilter("CIPixellate", parameters: [
                    kCIInputScaleKey: max(box.width, box.height) / 6,
                    kCIInputCenterKey: CIVector(x: box.midX, y: box.midY)
                ])
                .cropped(to: box)
            output = pixelated.composited(over: output)
        }
        return CIContext().createCGImage(output.cropped(to: extent), from: extent)
    }
}
