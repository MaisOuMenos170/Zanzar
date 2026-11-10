import CoreGraphics
import Testing
@testable import ZanzarProject

@Suite("PhotoCropGeometry")
struct PhotoCropGeometryTests {
    private static let wide = CGSize(width: 2000, height: 1000)
    private static let whole = CGRect(x: 0, y: 0, width: 1, height: 1)

    private func make(_ size: CGSize = PhotoCropGeometryTests.wide) -> PhotoCropGeometry {
        PhotoCropGeometry(sourceSize: size)
    }

    /// The frame's size in image pixels, before rounding.
    private func pixelSize(_ geometry: PhotoCropGeometry) -> CGSize {
        CGSize(
            width: geometry.cropRect.width * geometry.rotatedSize.width,
            height: geometry.cropRect.height * geometry.rotatedSize.height
        )
    }

    @Test("starts with the whole photo")
    func startsWithTheWholePhoto() {
        let geometry = make()
        #expect(geometry.cropRect == Self.whole)
        #expect(geometry.edit == PhotoEdit(quarterTurns: 0, cropRect: CGRect(x: 0, y: 0, width: 2000, height: 1000)))
    }

    @Test("rotating swaps the size and resets the frame")
    func rotatingSwapsSizeAndResetsTheFrame() {
        var geometry = make()
        geometry.drag(.right, to: CGPoint(x: 0.5, y: 0.5))
        geometry.rotate()
        #expect(geometry.rotatedSize == CGSize(width: 1000, height: 2000))
        #expect(geometry.cropRect == Self.whole)
        #expect(geometry.quarterTurns == 1)

        geometry.rotate()
        geometry.rotate()
        geometry.rotate()
        #expect(geometry.quarterTurns == 0)
        #expect(geometry.rotatedSize == Self.wide)
    }

    @Test("dragging a corner resizes from the opposite corner")
    func dragCornerResizesFromTheOppositeCorner() {
        var geometry = make()
        geometry.drag(.bottomRight, to: CGPoint(x: 0.5, y: 0.5))
        #expect(geometry.cropRect == CGRect(x: 0, y: 0, width: 0.5, height: 0.5))
    }

    @Test("a handle dragged outside the photo is clamped to it")
    func dragIsClampedToThePhoto() {
        var geometry = make()
        geometry.drag(.bottomRight, to: CGPoint(x: 0.5, y: 0.5))
        geometry.drag(.topLeft, to: CGPoint(x: -0.4, y: -0.4))
        #expect(geometry.cropRect.minX == 0)
        #expect(geometry.cropRect.minY == 0)

        geometry.drag(.right, to: CGPoint(x: 3, y: 0.5))
        #expect(geometry.cropRect.maxX == 1)
    }

    @Test("dragging an edge past the opposite edge stops at the minimum size")
    func dragPastTheOppositeEdgeStopsAtTheMinimum() {
        var geometry = make()
        geometry.drag(.left, to: CGPoint(x: 1, y: 0.5))
        #expect(geometry.cropRect.width > 0)
        #expect(pixelSize(geometry).width >= PhotoCropGeometry.minimumSide - 0.001)
        #expect(geometry.cropRect.maxX == 1)
    }

    @Test("zooming in never goes below the minimum side, and the pixel rect is whole numbers")
    func neverCropsBelowTheMinimumSide() {
        var geometry = make()
        geometry.zoom(by: 100)
        let rect = geometry.edit.cropRect
        #expect(rect.width >= 320)
        #expect(rect.height >= 320)
        #expect(rect.minX == rect.minX.rounded() && rect.minY == rect.minY.rounded())
        #expect(rect.width == rect.width.rounded() && rect.height == rect.height.rounded())
        #expect(rect.minX >= 0 && rect.minY >= 0 && rect.maxX <= 2000 && rect.maxY <= 1000)
    }

    @Test("a photo under 320 px on both sides cannot be cropped, but it can still be rotated")
    func smallPhotoCannotBeCropped() {
        var geometry = make(CGSize(width: 300, height: 200))
        #expect(geometry.canCrop == false)
        geometry.zoom(by: 2)
        geometry.drag(.right, to: CGPoint(x: 0.5, y: 0.5))
        #expect(geometry.cropRect == Self.whole)
        geometry.rotate()
        #expect(geometry.rotatedSize == CGSize(width: 200, height: 300))
    }

    @Test("a 320 px wide photo can only be cropped along its long side")
    func narrowPhotoCropsOneAxis() {
        var geometry = make(CGSize(width: 320, height: 2000))
        #expect(geometry.canCrop)
        geometry.drag(.left, to: CGPoint(x: 0.9, y: 0.5))
        #expect(geometry.cropRect.width == 1)
        geometry.drag(.bottom, to: CGPoint(x: 0.5, y: 0.5))
        #expect(geometry.cropRect.height == 0.5)
    }

    @Test("a locked ratio keeps its shape and the frame stays centered")
    func lockedRatioKeepsItsShape() {
        var geometry = make()
        geometry.setAspect(.square)
        var size = pixelSize(geometry)
        #expect(abs(size.width - size.height) < 1)
        #expect(abs(geometry.cropRect.midX - 0.5) < 0.0001)
        #expect(abs(geometry.cropRect.midY - 0.5) < 0.0001)

        geometry.zoom(by: 2)
        size = pixelSize(geometry)
        #expect(abs(size.width - size.height) < 1)
    }

    @Test("dragging a corner with a locked ratio keeps the ratio")
    func lockedRatioSurvivesDragging() {
        var geometry = make()
        geometry.setAspect(.sixteenByNine)
        geometry.drag(.topLeft, to: CGPoint(x: 0.4, y: 0.4))
        let size = pixelSize(geometry)
        #expect(abs(size.width / size.height - 16.0 / 9.0) < 0.01)
        #expect(geometry.cropRect.minX >= 0 && geometry.cropRect.maxX <= 1)
        #expect(geometry.cropRect.minY >= 0 && geometry.cropRect.maxY <= 1)
    }

    @Test("a ratio that cannot fit with the minimum side gives way, the minimum does not")
    func lockedRatioThatDoesNotFitStaysInside() {
        var geometry = make(CGSize(width: 320, height: 2048))
        geometry.setAspect(.sixteenByNine)
        let rect = geometry.cropRect
        #expect(rect.minX >= 0 && rect.minY >= 0 && rect.maxX <= 1 && rect.maxY <= 1)
        let size = pixelSize(geometry)
        #expect(size.width >= 320 - 0.001)
        #expect(size.height >= 320 - 0.001)
    }

    @Test("moving keeps the frame inside the photo and its size")
    func moveKeepsTheFrameInsideThePhoto() {
        var geometry = make()
        geometry.zoom(by: 2)
        let size = geometry.cropRect.size
        geometry.move(by: CGSize(width: 5, height: 5))
        #expect(geometry.cropRect.maxX == 1)
        #expect(geometry.cropRect.maxY == 1)
        #expect(geometry.cropRect.size == size)

        geometry.move(by: CGSize(width: -9, height: -9))
        #expect(geometry.cropRect.minX == 0)
        #expect(geometry.cropRect.minY == 0)
    }

    @Test("zooming out at an edge slides the frame inward and keeps its shape")
    func zoomOutAtAnEdgeKeepsTheShape() {
        var geometry = make()
        geometry.zoom(by: 2)
        geometry.move(by: CGSize(width: -5, height: -5))
        let before = pixelSize(geometry)

        geometry.zoom(by: 0.75)
        let after = pixelSize(geometry)
        #expect(abs(after.width / after.height - before.width / before.height) < 0.001)
        #expect(after.width > before.width)
        #expect(geometry.cropRect.minX >= 0 && geometry.cropRect.minY >= 0)
        #expect(geometry.cropRect.maxX <= 1 && geometry.cropRect.maxY <= 1)
    }

    @Test("reset goes back to the start")
    func resetGoesBackToTheStart() {
        var geometry = make()
        geometry.rotate()
        geometry.setAspect(.fourByFive)
        geometry.zoom(by: 2)
        geometry.reset()
        #expect(geometry == make())
    }
}
