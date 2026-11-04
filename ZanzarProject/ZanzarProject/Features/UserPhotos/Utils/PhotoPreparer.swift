import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

/// Turns whatever the user picked (HEIC, PNG, JPEG, from the library or the camera) into what is sent:
/// a JPEG of at most `maximumSide` px, orientation applied, with no metadata at all. The image is decoded
/// to pixels and re-encoded, so EXIF, GPS, the device model and dates cannot survive.
nonisolated enum PhotoPreparer {
    static let maximumSide = 2048
    static let jpegQuality = 0.8
    /// Files above this are refused before decoding (a 48 MP HEIC is about 10 MB).
    static let maximumInputBytes = 60 * 1024 * 1024

    enum Failure: Error, Equatable {
        case tooLarge
        case unreadable
    }

    /// Decodes and downsizes the picked file. Runs off the main actor: decoding a large photo takes a moment.
    @concurrent
    static func downsample(_ data: Data) async throws -> CGImage {
        guard data.count <= maximumInputBytes else { throw Failure.tooLarge }
        let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithData(data as CFData, sourceOptions),
              CGImageSourceGetCount(source) > 0 else {
            throw Failure.unreadable
        }
        let options = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maximumSide
        ] as CFDictionary
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options) else {
            throw Failure.unreadable
        }
        return image
    }

    /// Encodes pixels as a JPEG with no properties: nothing but the image itself is written.
    @concurrent
    static func encode(_ image: CGImage) async throws -> Data {
        let output = NSMutableData()
        let type = UTType.jpeg.identifier as CFString
        guard let destination = CGImageDestinationCreateWithData(output, type, 1, nil) else {
            throw Failure.unreadable
        }
        let properties = [kCGImageDestinationLossyCompressionQuality: jpegQuality] as CFDictionary
        CGImageDestinationAddImage(destination, image, properties)
        guard CGImageDestinationFinalize(destination) else { throw Failure.unreadable }
        return output as Data
    }

    /// EXIF keys ImageIO writes on its own for any JPEG: they describe the pixels, not the person or the phone.
    static let neutralExifKeys: Set<String> = [
        kCGImagePropertyExifColorSpace as String,
        kCGImagePropertyExifPixelXDimension as String,
        kCGImagePropertyExifPixelYDimension as String
    ]

    /// True when the JPEG carries location, device or date metadata. Used to check `encode`; never expected.
    static func containsIdentifyingMetadata(_ jpeg: Data) -> Bool {
        guard let source = CGImageSourceCreateWithData(jpeg as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] else {
            return false
        }
        if properties[kCGImagePropertyGPSDictionary] != nil || properties[kCGImagePropertyTIFFDictionary] != nil {
            return true
        }
        let exif = properties[kCGImagePropertyExifDictionary] as? [String: Any] ?? [:]
        return !Set(exif.keys).isSubset(of: neutralExifKeys)
    }
}
