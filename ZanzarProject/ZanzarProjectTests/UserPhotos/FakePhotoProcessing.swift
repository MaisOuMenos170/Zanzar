import CoreGraphics
import Foundation
@testable import ZanzarProject

/// Stands in for decoding, Vision and Core Image so view model tests need no real photos.
nonisolated final class FakePhotoProcessing: PhotoProcessing, @unchecked Sendable {
    var faces: [CGRect] = []
    var downsampleError: Error?
    private(set) var blurredFaces: [CGRect]?

    static let image: CGImage = {
        let context = CGContext(
            data: nil, width: 8, height: 6, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        )!
        return context.makeImage()!
    }()

    func downsample(_ data: Data) async throws -> CGImage {
        if let downsampleError { throw downsampleError }
        return Self.image
    }

    func faces(in image: CGImage) async -> [CGRect] { faces }

    func blur(_ faces: [CGRect], in image: CGImage) async -> CGImage? {
        blurredFaces = faces
        return Self.image
    }

    func encode(_ image: CGImage) async throws -> Data { Data([0xFF, 0xD8, 0xFF]) }
}

struct FixedSensitiveContent: SensitiveContentChecking {
    let answer: Bool?
    func isSensitive(_ image: CGImage) async -> Bool? { answer }
}
