import CoreGraphics

/// The same thresholds as the backend's face layer, so the device warns before the server would hold the photo.
nonisolated enum FacePolicy {
    /// A face covering at least 1% of the photo is in the foreground.
    static let prominentArea: CGFloat = 0.01
    static let crowdCount = 5

    static func prominentFaces(in faces: [CGRect]) -> [CGRect] {
        if faces.count >= crowdCount { return faces }
        return faces.filter { $0.width * $0.height >= prominentArea }
    }
}
