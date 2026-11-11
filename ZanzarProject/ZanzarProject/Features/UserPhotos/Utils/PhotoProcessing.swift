import CoreGraphics
import Foundation

/// The on-device steps of preparing a photo, behind a protocol so the ViewModel can be tested without images.
protocol PhotoProcessing: Sendable {
    func downsample(_ data: Data) async throws -> CGImage
    func faces(in image: CGImage) async -> [CGRect]
    func blur(_ faces: [CGRect], in image: CGImage) async -> CGImage?
    func edit(_ image: CGImage, _ edit: PhotoEdit) async -> CGImage?
    func encode(_ image: CGImage) async throws -> Data
}

nonisolated struct DevicePhotoProcessing: PhotoProcessing {
    func downsample(_ data: Data) async throws -> CGImage {
        try await PhotoPreparer.downsample(data)
    }

    func faces(in image: CGImage) async -> [CGRect] {
        await FaceDetector.faces(in: image)
    }

    func blur(_ faces: [CGRect], in image: CGImage) async -> CGImage? {
        await FaceBlurrer.blur(faces, in: image)
    }

    func edit(_ image: CGImage, _ edit: PhotoEdit) async -> CGImage? {
        await PhotoPreparer.edit(image, edit)
    }

    func encode(_ image: CGImage) async throws -> Data {
        try await PhotoPreparer.encode(image)
    }
}
