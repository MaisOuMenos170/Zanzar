import Foundation

/// How the map pins are grouped at the current zoom. Clustering depends only on this value (and the
/// places), never on where the camera is pointing, so panning cannot change which pins are shown.
enum MapPinZoomLevel: Equatable, Sendable {
    /// Close enough that every place gets its own pin.
    case individual
    /// A half-octave bucket of the visible span: `level` covers spans of `2^(level / 2)` up to the next level.
    case grouped(Int)
}
