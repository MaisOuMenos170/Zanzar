import CoreGraphics
import Foundation

/// A photo ready to leave the device: a JPEG of at most 2048 px with no metadata (no EXIF, GPS or device model).
nonisolated struct PreparedPhoto: Sendable {
    let jpeg: Data
    let width: Int
    let height: Int
    /// Faces large enough to make the person recognizable, in normalized coordinates (origin bottom-left).
    let prominentFaces: [CGRect]
}
