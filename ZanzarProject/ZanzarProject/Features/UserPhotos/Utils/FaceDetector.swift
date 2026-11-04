import CoreGraphics
import CoreML
import Vision

/// Finds faces with Vision on the device. The backend repeats the check: the device is not trusted.
nonisolated enum FaceDetector {
    /// Face boxes in normalized coordinates (origin bottom-left). An analysis failure returns no faces,
    /// which only skips the device warning; the server's check still runs.
    @concurrent
    static func faces(in image: CGImage) async -> [CGRect] {
        if let faces = try? detect(in: image, cpuOnly: false) {
            return faces
        }
        // Without a usable GPU or Neural Engine (the Simulator, some low-power states) the default device
        // fails; the CPU always works, only slower.
        do {
            return try detect(in: image, cpuOnly: true)
        } catch {
            AppLog.userPhotos.error("Face detection failed", error: error)
            return []
        }
    }

    private static func detect(in image: CGImage, cpuOnly: Bool) throws -> [CGRect] {
        let request = VNDetectFaceRectanglesRequest()
        if cpuOnly, let cpu = MLComputeDevice.allComputeDevices.first(where: { if case .cpu = $0 { true } else { false } }) {
            request.setComputeDevice(cpu, for: .main)
        }
        try VNImageRequestHandler(cgImage: image, options: [:]).perform([request])
        return (request.results ?? []).map(\.boundingBox)
    }
}
