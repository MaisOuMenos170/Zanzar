import SwiftUI

/// Crop, zoom and turn a photo before it is checked and sent. The rules live in `PhotoCropGeometry`; this view
/// shows the photo (already turned), the frame, and the controls.
struct PhotoEditorView: View {
    let image: CGImage
    let onConfirm: (PhotoEdit) -> Void
    let onChooseAnother: () -> Void

    @State private var geometry: PhotoCropGeometry

    init(image: CGImage, onConfirm: @escaping (PhotoEdit) -> Void, onChooseAnother: @escaping () -> Void) {
        self.image = image
        self.onConfirm = onConfirm
        self.onChooseAnother = onChooseAnother
        _geometry = State(
            initialValue: PhotoCropGeometry(sourceSize: CGSize(width: image.width, height: image.height))
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            canvas
            if !geometry.canCrop {
                Text("userPhotos.editor.tooSmall.hint")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 8)
            }
            controls
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("userPhotos.editor.useButton.title") { onConfirm(geometry.edit) }
            }
        }
    }

    // MARK: - Canvas

    private var canvas: some View {
        GeometryReader { proxy in
            let imageFrame = fitted(geometry.rotatedSize, in: proxy.size)
            ZStack {
                // Turned by the view, in the same call that turns the geometry, so the two never disagree. The frame
                // is laid out before the turn: for an odd number of turns its sides are swapped.
                Image(decorative: image, scale: 1)
                    .resizable()
                    .frame(
                        width: geometry.quarterTurns.isMultiple(of: 2) ? imageFrame.width : imageFrame.height,
                        height: geometry.quarterTurns.isMultiple(of: 2) ? imageFrame.height : imageFrame.width
                    )
                    .rotationEffect(.degrees(Double(geometry.quarterTurns) * 90))
                    .position(x: imageFrame.midX, y: imageFrame.midY)
                    .accessibilityHidden(true)
                PhotoCropOverlay(geometry: $geometry, imageFrame: imageFrame)
            }
            .coordinateSpace(.named(PhotoCropOverlay.space))
        }
        .padding(16)
    }

    private func fitted(_ size: CGSize, in container: CGSize) -> CGRect {
        guard size.width > 0, size.height > 0, container.width > 0, container.height > 0 else { return .zero }
        let scale = min(container.width / size.width, container.height / size.height)
        let fitted = CGSize(width: size.width * scale, height: size.height * scale)
        return CGRect(
            x: (container.width - fitted.width) / 2, y: (container.height - fitted.height) / 2,
            width: fitted.width, height: fitted.height
        )
    }

    // MARK: - Controls

    private var controls: some View {
        HStack(spacing: 0) {
            control("userPhotos.editor.rotateButton.label", systemImage: "rotate.right") { geometry.rotate() }
            aspectMenu
            control("userPhotos.editor.resetButton.label", systemImage: "arrow.counterclockwise") { geometry.reset() }
            control("userPhotos.upload.preview.anotherButton.title", systemImage: "photo.on.rectangle") {
                onChooseAnother()
            }
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
    }

    private func control(
        _ title: LocalizedStringKey, systemImage: String, action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.title3)
                Text(title)
                    .font(.caption)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, minHeight: 56)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    private var aspectMenu: some View {
        Menu {
            Picker(
                "userPhotos.editor.aspectMenu.label",
                selection: Binding(get: { geometry.aspect }, set: { geometry.setAspect($0) })
            ) {
                ForEach(PhotoCropGeometry.AspectRatio.allCases, id: \.self) { aspect in
                    aspect.title.tag(aspect)
                }
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: "aspectratio")
                    .font(.title3)
                Text("userPhotos.editor.aspectMenu.label")
                    .font(.caption)
            }
            .frame(maxWidth: .infinity, minHeight: 56)
            .contentShape(.rect)
        }
        .foregroundStyle(.primary)
        .disabled(!geometry.canCrop)
    }
}

private extension PhotoCropGeometry.AspectRatio {
    var title: Text {
        switch self {
        case .free: Text("userPhotos.editor.aspect.free")
        case .square: Text(verbatim: "1:1")
        case .fourByFive: Text(verbatim: "4:5")
        case .sixteenByNine: Text(verbatim: "16:9")
        }
    }
}

#if DEBUG
private func previewPhoto(width: Int, height: Int) -> CGImage {
    let context = CGContext(
        data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
        space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
    )!
    let colors = [
        CGColor(red: 0.95, green: 0.55, blue: 0.2, alpha: 1),
        CGColor(red: 0.2, green: 0.45, blue: 0.85, alpha: 1)
    ]
    let gradient = CGGradient(colorsSpace: nil, colors: colors as CFArray, locations: [0, 1])!
    context.drawLinearGradient(
        gradient, start: .zero, end: CGPoint(x: width, y: height), options: []
    )
    return context.makeImage()!
}

#Preview("Landscape photo") {
    NavigationStack {
        PhotoEditorView(image: previewPhoto(width: 2048, height: 1365), onConfirm: { _ in }, onChooseAnother: {})
            .navigationTitle("userPhotos.editor.title")
            .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("Photo too small to crop") {
    NavigationStack {
        PhotoEditorView(image: previewPhoto(width: 300, height: 200), onConfirm: { _ in }, onChooseAnother: {})
            .navigationTitle("userPhotos.editor.title")
            .navigationBarTitleDisplayMode(.inline)
    }
}
#endif
