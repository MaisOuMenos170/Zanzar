import CoreGraphics
import Foundation
import Testing
@testable import ZanzarProject

@Suite("PhotoPreparer.edit")
struct PhotoPreparerEditTests {
    /// Colour management shifts the sample's pure red and blue a little, so a pixel is read as the stronger channel.
    private enum Tint: Equatable {
        case red, blue
    }

    private static let red = Tint.red
    private static let blue = Tint.blue

    /// 4 by 2 px: the two left columns are red, the two right ones blue.
    private func sample() throws -> CGImage {
        let context = try #require(CGContext(
            data: nil, width: 4, height: 2, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ))
        context.setFillColor(CGColor(red: 1, green: 0, blue: 0, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: 2, height: 2))
        context.setFillColor(CGColor(red: 0, green: 0, blue: 1, alpha: 1))
        context.fill(CGRect(x: 2, y: 0, width: 2, height: 2))
        return try #require(context.makeImage())
    }

    /// The pixel at (x, y), counting from the top left.
    private func pixel(_ image: CGImage, _ x: Int, _ y: Int) throws -> Tint {
        let context = try #require(CGContext(
            data: nil, width: image.width, height: image.height, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ))
        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        let data = try #require(context.data).assumingMemoryBound(to: UInt8.self)
        let offset = y * context.bytesPerRow + x * 4
        return data[offset] > data[offset + 2] ? .red : .blue
    }

    @Test("no turn and the whole photo keeps the size")
    func identityKeepsTheSize() async throws {
        let edited = await PhotoPreparer.edit(
            try sample(), PhotoEdit(quarterTurns: 0, cropRect: CGRect(x: 0, y: 0, width: 4, height: 2))
        )
        let image = try #require(edited)
        #expect(image.width == 4 && image.height == 2)
        #expect(try pixel(image, 0, 0) == Self.red)
        #expect(try pixel(image, 3, 1) == Self.blue)
    }

    @Test("a quarter turn goes clockwise: the left side ends up on top")
    func rotatesClockwise() async throws {
        let edited = await PhotoPreparer.edit(
            try sample(), PhotoEdit(quarterTurns: 1, cropRect: CGRect(x: 0, y: 0, width: 2, height: 4))
        )
        let image = try #require(edited)
        #expect(image.width == 2 && image.height == 4)
        #expect(try pixel(image, 0, 0) == Self.red)
        #expect(try pixel(image, 0, 3) == Self.blue)
    }

    @Test("the crop is taken from the turned photo")
    func cropsAfterRotating() async throws {
        let edited = await PhotoPreparer.edit(
            try sample(), PhotoEdit(quarterTurns: 1, cropRect: CGRect(x: 0, y: 0, width: 2, height: 2))
        )
        let image = try #require(edited)
        #expect(image.width == 2 && image.height == 2)
        #expect(try pixel(image, 0, 0) == Self.red)
        #expect(try pixel(image, 1, 1) == Self.red)
    }

    @Test("a half turn flips both axes")
    func halfTurnFlipsBothAxes() async throws {
        let edited = await PhotoPreparer.edit(
            try sample(), PhotoEdit(quarterTurns: 2, cropRect: CGRect(x: 0, y: 0, width: 4, height: 2))
        )
        let image = try #require(edited)
        #expect(try pixel(image, 0, 0) == Self.blue)
        #expect(try pixel(image, 3, 1) == Self.red)
    }

    @Test("an empty rectangle or one that leaves the photo gives nothing")
    func rejectsAnEmptyOrOutOfBoundsRect() async throws {
        let image = try sample()
        let empty = await PhotoPreparer.edit(image, PhotoEdit(quarterTurns: 0, cropRect: CGRect(x: 1, y: 0, width: 0, height: 2)))
        let outside = await PhotoPreparer.edit(image, PhotoEdit(quarterTurns: 0, cropRect: CGRect(x: 3, y: 0, width: 4, height: 2)))
        #expect(empty == nil)
        #expect(outside == nil)
    }

    @Test("an edited photo still encodes without any metadata")
    func editedPhotoStillEncodesWithoutMetadata() async throws {
        let edited = await PhotoPreparer.edit(
            try sample(), PhotoEdit(quarterTurns: 1, cropRect: CGRect(x: 0, y: 0, width: 2, height: 4))
        )
        let jpeg = try await PhotoPreparer.encode(try #require(edited))
        #expect(PhotoPreparer.containsIdentifyingMetadata(jpeg) == false)
    }
}
