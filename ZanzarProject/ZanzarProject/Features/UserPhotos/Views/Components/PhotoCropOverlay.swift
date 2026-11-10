import SwiftUI

/// The crop frame over the photo: the dimmed outside, a thirds grid and eight handles. It only turns touches into
/// calls on the geometry; every rule (limits, ratio, minimum size) lives there.
///
/// Gesture bookkeeping lives in `@GestureState`, which SwiftUI resets when a gesture ends *or is cancelled*, so a
/// cancelled touch cannot leave stale values that make the next one jump.
struct PhotoCropOverlay: View {
    @Binding var geometry: PhotoCropGeometry
    /// Where the photo is drawn, in the coordinate space named `Self.space`.
    let imageFrame: CGRect

    static let space = "photoCropCanvas"
    /// How far one VoiceOver "move" action shifts the frame, as a fraction of the photo.
    private static let accessibilityMoveStep: CGFloat = 0.05

    @GestureState private var lastTranslation = CGSize.zero
    @GestureState private var lastMagnification: CGFloat = 1

    private var frame: CGRect {
        let rect = geometry.cropRect
        return CGRect(
            x: imageFrame.minX + rect.minX * imageFrame.width,
            y: imageFrame.minY + rect.minY * imageFrame.height,
            width: rect.width * imageFrame.width,
            height: rect.height * imageFrame.height
        )
    }

    var body: some View {
        ZStack {
            dimming
            Rectangle()
                .strokeBorder(.white, lineWidth: 1.5)
                .frame(width: frame.width, height: frame.height)
                .position(x: frame.midX, y: frame.midY)
                .allowsHitTesting(false)
            grid
            movingArea
            if geometry.canCrop {
                ForEach(Self.handles, id: \.self) { handle in
                    CropHandle(
                        handle: handle, center: center(of: handle), geometry: $geometry, imageFrame: imageFrame
                    )
                }
            }
        }
        .contentShape(.rect)
        .simultaneousGesture(pinch)
    }

    // MARK: - Drawing

    private var dimming: some View {
        Path { path in
            path.addRect(imageFrame)
            path.addRect(frame)
        }
        .fill(.black.opacity(0.55), style: FillStyle(eoFill: true))
        .allowsHitTesting(false)
    }

    private var grid: some View {
        Path { path in
            for step in [1.0, 2.0] {
                let column = frame.minX + frame.width * step / 3
                let row = frame.minY + frame.height * step / 3
                path.move(to: CGPoint(x: column, y: frame.minY))
                path.addLine(to: CGPoint(x: column, y: frame.maxY))
                path.move(to: CGPoint(x: frame.minX, y: row))
                path.addLine(to: CGPoint(x: frame.maxX, y: row))
            }
        }
        .stroke(.white.opacity(0.4), lineWidth: 0.5)
        .allowsHitTesting(false)
    }

    // MARK: - Moving and zooming

    private var movingArea: some View {
        Color.clear
            .contentShape(.rect)
            .frame(width: frame.width, height: frame.height)
            .position(x: frame.midX, y: frame.midY)
            .gesture(
                DragGesture()
                    .updating($lastTranslation) { value, last, _ in
                        let delta = CGSize(
                            width: value.translation.width - last.width,
                            height: value.translation.height - last.height
                        )
                        last = value.translation
                        geometry.move(by: CGSize(
                            width: delta.width / max(imageFrame.width, 1),
                            height: delta.height / max(imageFrame.height, 1)
                        ))
                    }
            )
            .accessibilityElement()
            .accessibilityLabel(Text("userPhotos.editor.frame.accessibilityLabel"))
            .accessibilityHint(Text("userPhotos.editor.frame.accessibilityHint"))
            .accessibilityValue(Text(verbatim: sizeDescription))
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment: geometry.zoom(by: 0.9)
                case .decrement: geometry.zoom(by: 1.1)
                @unknown default: break
                }
            }
            .accessibilityAction(named: Text("userPhotos.editor.move.left")) { shift(horizontal: -Self.accessibilityMoveStep) }
            .accessibilityAction(named: Text("userPhotos.editor.move.right")) { shift(horizontal: Self.accessibilityMoveStep) }
            .accessibilityAction(named: Text("userPhotos.editor.move.up")) { shift(vertical: -Self.accessibilityMoveStep) }
            .accessibilityAction(named: Text("userPhotos.editor.move.down")) { shift(vertical: Self.accessibilityMoveStep) }
    }

    private func shift(horizontal: CGFloat = 0, vertical: CGFloat = 0) {
        geometry.move(by: CGSize(width: horizontal, height: vertical))
    }

    /// The frame size in photo pixels, for VoiceOver to read after each change.
    private var sizeDescription: String {
        let rect = geometry.edit.cropRect
        return "\(Int(rect.width)) × \(Int(rect.height)) px"
    }

    private var pinch: some Gesture {
        MagnifyGesture()
            .updating($lastMagnification) { value, last, _ in
                geometry.zoom(by: value.magnification / max(last, .leastNonzeroMagnitude))
                last = value.magnification
            }
    }

    // MARK: - Handles

    private static let handles: [PhotoCropGeometry.Handle] = [
        .topLeft, .top, .topRight, .right, .bottomRight, .bottom, .bottomLeft, .left
    ]

    private func center(of handle: PhotoCropGeometry.Handle) -> CGPoint {
        switch handle {
        case .topLeft: CGPoint(x: frame.minX, y: frame.minY)
        case .top: CGPoint(x: frame.midX, y: frame.minY)
        case .topRight: CGPoint(x: frame.maxX, y: frame.minY)
        case .right: CGPoint(x: frame.maxX, y: frame.midY)
        case .bottomRight: CGPoint(x: frame.maxX, y: frame.maxY)
        case .bottom: CGPoint(x: frame.midX, y: frame.maxY)
        case .bottomLeft: CGPoint(x: frame.minX, y: frame.maxY)
        case .left: CGPoint(x: frame.minX, y: frame.midY)
        }
    }
}

/// One handle of the frame. Each handle owns its gesture state, so two fingers on two handles never share it.
private struct CropHandle: View {
    let handle: PhotoCropGeometry.Handle
    /// Where the handle is drawn now, in the canvas space.
    let center: CGPoint
    @Binding var geometry: PhotoCropGeometry
    let imageFrame: CGRect

    private static let touchSize: CGFloat = 44

    /// Where the finger grabbed the handle, relative to its center. Resets when the gesture ends or is cancelled.
    @GestureState private var grab: CGSize?

    var body: some View {
        shape
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.4), radius: 2)
            .frame(width: Self.touchSize, height: Self.touchSize)
            .contentShape(.rect)
            .position(center)
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .named(PhotoCropOverlay.space))
                    .updating($grab) { value, grab, _ in
                        // Keep the finger where it grabbed the handle, so the frame does not jump.
                        let offset = grab ?? CGSize(
                            width: center.x - value.startLocation.x, height: center.y - value.startLocation.y
                        )
                        grab = offset
                        geometry.drag(handle, to: CGPoint(
                            x: (value.location.x + offset.width - imageFrame.minX) / max(imageFrame.width, 1),
                            y: (value.location.y + offset.height - imageFrame.minY) / max(imageFrame.height, 1)
                        ))
                    }
            )
            // VoiceOver adjusts the frame as a whole (see `PhotoCropOverlay.movingArea`); the handles are for touch.
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private var shape: some View {
        switch handle {
        case .top, .bottom:
            Capsule().frame(width: 28, height: 5)
        case .left, .right:
            Capsule().frame(width: 5, height: 28)
        default:
            Circle().frame(width: 16, height: 16)
        }
    }
}
