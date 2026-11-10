import CoreGraphics

/// The rules of the photo editor: rotation and the crop frame, kept apart from SwiftUI so they can be tested.
///
/// The frame (`cropRect`) is normalized (0 to 1) in the space of the turned photo, origin at the top left. It never
/// leaves the photo, and its sides never go below `minimumSide` px of the photo (the backend refuses smaller ones),
/// except on an axis where the photo itself is smaller than that.
nonisolated struct PhotoCropGeometry: Equatable, Sendable {
    enum AspectRatio: CaseIterable, Sendable {
        case free, square, fourByFive, sixteenByNine

        /// Width over height; `nil` when the frame is free.
        var ratio: CGFloat? {
            switch self {
            case .free: nil
            case .square: 1
            case .fourByFive: 4.0 / 5.0
            case .sixteenByNine: 16.0 / 9.0
            }
        }
    }

    enum Handle: Sendable {
        case topLeft, top, topRight, right, bottomRight, bottom, bottomLeft, left
    }

    /// What stays still on one axis while the frame changes size.
    private enum Anchor {
        case low, high, center
    }

    static let minimumSide: CGFloat = 320

    let sourceSize: CGSize
    private(set) var quarterTurns = 0
    private(set) var aspect = AspectRatio.free
    private(set) var cropRect = CGRect(x: 0, y: 0, width: 1, height: 1)

    init(sourceSize: CGSize) {
        self.sourceSize = sourceSize
    }

    var rotatedSize: CGSize {
        quarterTurns.isMultiple(of: 2) ? sourceSize : CGSize(width: sourceSize.height, height: sourceSize.width)
    }

    /// False when the frame cannot be smaller than the photo on either axis.
    var canCrop: Bool {
        minimumFraction.width < 1 || minimumFraction.height < 1
    }

    /// The frame in whole pixels of the turned photo.
    var edit: PhotoEdit {
        let size = rotatedSize
        let horizontal = pixelRange(cropRect.minX, cropRect.maxX, of: size.width)
        let vertical = pixelRange(cropRect.minY, cropRect.maxY, of: size.height)
        return PhotoEdit(
            quarterTurns: quarterTurns,
            cropRect: CGRect(
                x: horizontal.lowerBound, y: vertical.lowerBound,
                width: horizontal.upperBound - horizontal.lowerBound,
                height: vertical.upperBound - vertical.lowerBound
            )
        )
    }

    // MARK: - Changes

    mutating func rotate() {
        quarterTurns = (quarterTurns + 1) % 4
        cropRect = CGRect(x: 0, y: 0, width: 1, height: 1)
        setAspect(aspect)
    }

    mutating func reset() {
        self = PhotoCropGeometry(sourceSize: sourceSize)
    }

    /// Locks the frame to a ratio: the biggest frame of that shape around the current center. Free keeps the frame.
    mutating func setAspect(_ aspect: AspectRatio) {
        self.aspect = aspect
        guard let shape = shape(for: aspect) else { return }
        cropRect = fitted(width: 1, height: 1 / shape, anchorX: .center, anchorY: .center)
    }

    /// Drags a handle to a point of the photo (normalized). The opposite side stays where it is.
    mutating func drag(_ handle: Handle, to point: CGPoint) {
        let point = CGPoint(x: min(max(point.x, 0), 1), y: min(max(point.y, 0), 1))
        let rect = cropRect
        let movesLeft = [.topLeft, .left, .bottomLeft].contains(handle)
        let movesRight = [.topRight, .right, .bottomRight].contains(handle)
        let movesTop = [.topLeft, .top, .topRight].contains(handle)
        let movesBottom = [.bottomLeft, .bottom, .bottomRight].contains(handle)

        var width = rect.width
        var height = rect.height
        var anchorX = Anchor.low
        var anchorY = Anchor.low
        if movesLeft {
            width = rect.maxX - point.x
            anchorX = .high
        } else if movesRight {
            width = point.x - rect.minX
        }
        if movesTop {
            height = rect.maxY - point.y
            anchorY = .high
        } else if movesBottom {
            height = point.y - rect.minY
        }

        if let shape = shape(for: aspect) {
            let horizontal = movesLeft || movesRight
            let vertical = movesTop || movesBottom
            if horizontal && vertical {
                width = max(width, shape * height)
                height = width / shape
            } else if horizontal {
                height = width / shape
                anchorY = .center
            } else {
                width = shape * height
                anchorX = .center
            }
        }
        cropRect = fitted(width: width, height: height, anchorX: anchorX, anchorY: anchorY)
    }

    /// Moves the frame by a distance in normalized units, keeping it inside the photo.
    mutating func move(by delta: CGSize) {
        cropRect.origin.x = min(max(cropRect.minX + delta.width, 0), 1 - cropRect.width)
        cropRect.origin.y = min(max(cropRect.minY + delta.height, 0), 1 - cropRect.height)
    }

    /// Pinch: a factor above 1 makes the frame smaller, around its center.
    mutating func zoom(by factor: CGFloat) {
        guard factor > 0, factor.isFinite else { return }
        cropRect = fitted(
            width: cropRect.width / factor, height: cropRect.height / factor, anchorX: .center, anchorY: .center
        )
    }

    // MARK: - Rules

    /// The smallest frame side, as a fraction of the turned photo, per axis. 1 means the whole side.
    private var minimumFraction: CGSize {
        let size = rotatedSize
        return CGSize(
            width: size.width > 0 ? min(1, Self.minimumSide / size.width) : 1,
            height: size.height > 0 ? min(1, Self.minimumSide / size.height) : 1
        )
    }

    /// Width over height of the frame in normalized units, for a locked ratio.
    private func shape(for aspect: AspectRatio) -> CGFloat? {
        let size = rotatedSize
        guard let ratio = aspect.ratio, size.width > 0, size.height > 0 else { return nil }
        return ratio * size.height / size.width
    }

    /// A frame as close to the wanted size as the rules allow, placed around the anchors of the current frame.
    private func fitted(width: CGFloat, height: CGFloat, anchorX: Anchor, anchorY: Anchor) -> CGRect {
        let minimum = minimumFraction
        let roomX = room(anchorX, low: cropRect.minX, high: cropRect.maxX)
        let roomY = room(anchorY, low: cropRect.minY, high: cropRect.maxY)
        var width = width
        var height = height

        if let shape = shape(for: aspect) {
            // Shrink to what is available, keeping the ratio; then grow to the minimum if the ratio still allows it.
            let shrink = min(1, roomX / max(width, .leastNonzeroMagnitude), roomY / max(height, .leastNonzeroMagnitude))
            width *= shrink
            height *= shrink
            let grow = max(1, minimum.width / max(width, .leastNonzeroMagnitude),
                           minimum.height / max(height, .leastNonzeroMagnitude))
            let grownWidth = width * grow
            let grownHeight = grownWidth / shape
            if grownWidth <= roomX + 1e-9, grownHeight <= roomY + 1e-9 {
                width = grownWidth
                height = grownHeight
            }
        }
        // The ratio gives way before the photo bounds or the minimum side do.
        width = min(max(width, minimum.width), max(roomX, minimum.width))
        height = min(max(height, minimum.height), max(roomY, minimum.height))

        let left = switch anchorX {
        case .low: cropRect.minX
        case .high: cropRect.maxX - width
        case .center: cropRect.midX - width / 2
        }
        let top = switch anchorY {
        case .low: cropRect.minY
        case .high: cropRect.maxY - height
        case .center: cropRect.midY - height / 2
        }
        return CGRect(
            x: min(max(left, 0), 1 - width), y: min(max(top, 0), 1 - height), width: width, height: height
        )
    }

    /// How far a frame side can grow on an axis, given what stays still.
    private func room(_ anchor: Anchor, low: CGFloat, high: CGFloat) -> CGFloat {
        switch anchor {
        case .low: 1 - low
        case .high: high
        case .center: 2 * min((low + high) / 2, 1 - (low + high) / 2)
        }
    }

    /// Whole pixels covering a normalized span, never narrower than the minimum side.
    private func pixelRange(_ low: CGFloat, _ high: CGFloat, of length: CGFloat) -> Range<CGFloat> {
        guard length >= 1 else { return 0 ..< max(length, 0) }
        var start = (low * length + 1e-6).rounded(.down)
        var end = (high * length - 1e-6).rounded(.up)
        start = min(max(start, 0), length)
        end = min(max(end, start), length)
        let minimum = min(Self.minimumSide, length)
        if end - start < minimum {
            end = min(length, start + minimum)
            start = end - minimum
        }
        return start ..< end
    }
}
