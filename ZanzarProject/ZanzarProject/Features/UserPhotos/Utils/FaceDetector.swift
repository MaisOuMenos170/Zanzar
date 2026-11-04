import CoreGraphics
import Vision

/// Finds faces with Vision on the device. The backend repeats the check: the device is not trusted.
nonisolated enum FaceDetector {
    /// Face boxes in normalized coordinates (origin bottom-left). An analysis failure returns no faces,
    /// which only skips the device warning; the server's check still runs.
    @concurrent
    static func faces(in image: CGImage) async -> [CGRect] {
        let request = VNDetectFaceRectanglesRequest()
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        do {
            try handler.perform([request])
        } catch {
            AppLog.userPhotos.warning("Face detection failed")
            return []
        }
        return (request.results ?? []).map(\.boundingBox)
    }
}
