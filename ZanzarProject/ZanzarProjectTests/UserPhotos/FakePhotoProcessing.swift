import CoreGraphics
import Foundation
@testable import ZanzarProject

/// Stands in for decoding, Vision and Core Image so view model tests need no real photos.
nonisolated final class FakePhotoProcessing: PhotoProcessing, @unchecked Sendable {
    var faces: [CGRect] = []
    var downsampleError: Error?
    private(set) var blurredFaces: [CGRect]?
    /// A different image from the one `downsample` returns, so tests can tell which of the two was used.
    var editResult: CGImage? = FakePhotoProcessing.edited
    private(set) var appliedEdits: [PhotoEdit] = []
    private(set) var facesRequestedFor: [CGImage] = []
    private(set) var encodedImages: [CGImage] = []

    static let edited: CGImage = {
        let context = CGContext(
            data: nil, width: 4, height: 3, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        )!
        return context.makeImage()!
    }()

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

    func faces(in image: CGImage) async -> [CGRect] {
        facesRequestedFor.append(image)
        return faces
    }

    func blur(_ faces: [CGRect], in image: CGImage) async -> CGImage? {
        blurredFaces = faces
        return Self.image
    }

    func edit(_ image: CGImage, _ edit: PhotoEdit) async -> CGImage? {
        appliedEdits.append(edit)
        return editResult
    }

    func encode(_ image: CGImage) async throws -> Data {
        encodedImages.append(image)
        return Data([0xFF, 0xD8, 0xFF])
    }
}

final class FixedSensitiveContent: SensitiveContentChecking, @unchecked Sendable {
    let answer: Bool?
    private(set) var checkedImages: [CGImage] = []

    init(answer: Bool?) {
        self.answer = answer
    }

    func isSensitive(_ image: CGImage) async -> Bool? {
        checkedImages.append(image)
        return answer
    }
}
