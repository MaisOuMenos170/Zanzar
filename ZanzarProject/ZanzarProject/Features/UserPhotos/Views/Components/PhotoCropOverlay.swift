import SwiftUI

/// The crop frame over the photo: the dimmed outside, a thirds grid and eight handles. It only turns touches into
/// calls on the geometry; every rule (limits, ratio, minimum size) lives there.
struct PhotoCropOverlay: View {
    @Binding var geometry: PhotoCropGeometry
    /// Where the photo is drawn, in the coordinate space named `Self.space`.
    let imageFrame: CGRect

    static let space = "photoCropCanvas"
    private static let touchSize: CGFloat = 44

    @State private var grabOffset: CGSize?
    @State private var lastTranslation = CGSize.zero
    @State private var lastMagnification: CGFloat = 1

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
                    handleView(handle)
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
                let x = frame.minX + frame.width * step / 3
                let y = frame.minY + frame.height * step / 3
                path.move(to: CGPoint(x: x, y: frame.minY))
                path.addLine(to: CGPoint(x: x, y: frame.maxY))
                path.move(to: CGPoint(x: frame.minX, y: y))
                path.addLine(to: CGPoint(x: frame.maxX, y: y))
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
                    .onChanged { value in
                        let delta = CGSize(
                            width: value.translation.width - lastTranslation.width,
                            height: value.translation.height - lastTranslation.height
                        )
                        lastTranslation = value.translation
                        geometry.move(by: CGSize(
                            width: delta.width / max(imageFrame.width, 1),
                            height: delta.height / max(imageFrame.height, 1)
                        ))
                    }
                    .onEnded { _ in lastTranslation = .zero }
            )
            .accessibilityElement()
            .accessibilityLabel(Text("userPhotos.editor.frame.accessibilityLabel"))
            .accessibilityHint(Text("userPhotos.editor.frame.accessibilityHint"))
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment: geometry.zoom(by: 0.9)
                case .decrement: geometry.zoom(by: 1.1)
                @unknown default: break
                }
            }
    }

    private var pinch: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                geometry.zoom(by: value.magnification / lastMagnification)
                lastMagnification = value.magnification
            }
            .onEnded { _ in lastMagnification = 1 }
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

    @ViewBuilder
    private func handleShape(_ handle: PhotoCropGeometry.Handle) -> some View {
        switch handle {
        case .top, .bottom:
            Capsule().frame(width: 28, height: 5)
        case .left, .right:
            Capsule().frame(width: 5, height: 28)
        default:
            Circle().frame(width: 16, height: 16)
        }
    }

    private func handleView(_ handle: PhotoCropGeometry.Handle) -> some View {
        let origin = center(of: handle)
        return handleShape(handle)
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.4), radius: 2)
            .frame(width: Self.touchSize, height: Self.touchSize)
            .contentShape(.rect)
            .position(origin)
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .named(Self.space))
                    .onChanged { value in
                        // Keep the finger where it grabbed the handle, so the frame does not jump.
                        let grab = grabOffset ?? CGSize(
                            width: center(of: handle).x - value.startLocation.x,
                            height: center(of: handle).y - value.startLocation.y
                        )
                        grabOffset = grab
                        let point = CGPoint(
                            x: (value.location.x + grab.width - imageFrame.minX) / max(imageFrame.width, 1),
                            y: (value.location.y + grab.height - imageFrame.minY) / max(imageFrame.height, 1)
                        )
                        geometry.drag(handle, to: point)
                    }
                    .onEnded { _ in grabOffset = nil }
            )
            // VoiceOver adjusts the frame as a whole (see `movingArea`); the handles are for touch.
            .accessibilityHidden(true)
    }
}
