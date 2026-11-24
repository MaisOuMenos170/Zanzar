import SwiftUI
import Testing

@testable import ZanzarProject

@MainActor
@Suite("scaledFont")
struct ScaledFontModifierTests {
    private func renderedHeight(size: CGFloat, dynamicTypeSize: DynamicTypeSize) -> CGFloat? {
        let text = Text("Lero").scaledFont(size: size).environment(\.dynamicTypeSize, dynamicTypeSize)
        let renderer = ImageRenderer(content: text)
        renderer.scale = 1
        return renderer.uiImage?.size.height
    }

    @Test("Text grows when the user asks for larger text")
    func growsWithDynamicType() throws {
        let standard = try #require(renderedHeight(size: 14, dynamicTypeSize: .large))
        let accessible = try #require(renderedHeight(size: 14, dynamicTypeSize: .accessibility5))

        #expect(accessible > standard * 1.5)
    }

    @Test("Text is the same as a fixed system font at the default text size")
    func sameAtDefaultSize() throws {
        let scaled = try #require(renderedHeight(size: 14, dynamicTypeSize: .large))
        let fixed = try #require({ () -> CGFloat? in
            let renderer = ImageRenderer(content: Text("Lero").font(.system(size: 14)))
            renderer.scale = 1
            return renderer.uiImage?.size.height
        }())

        #expect(abs(scaled - fixed) < 0.5)
    }

    @Test("Each design size follows the text style closest to it")
    func textStyleForSize() {
        #expect(ScaledFontModifier.textStyle(for: 9) == .caption2)
        #expect(ScaledFontModifier.textStyle(for: 12) == .caption)
        #expect(ScaledFontModifier.textStyle(for: 14) == .footnote)
        #expect(ScaledFontModifier.textStyle(for: 16) == .callout)
        #expect(ScaledFontModifier.textStyle(for: 17) == .body)
        #expect(ScaledFontModifier.textStyle(for: 22) == .title2)
    }
}

@Suite("minimumTouch")
struct MinimumTouchShapeTests {
    @Test("A small control gets a 44×44 touch area around its center")
    func growsSmallControls() {
        let area = MinimumTouchShape.touchRect(for: CGRect(x: 10, y: 20, width: 30, height: 20))

        #expect(area.width == 44)
        #expect(area.height == 44)
        #expect(area.midX == 25)
        #expect(area.midY == 30)
    }

    @Test("A control that is already big enough keeps its size")
    func keepsBigControls() {
        let rect = CGRect(x: 0, y: 0, width: 300, height: 56)

        #expect(MinimumTouchShape.touchRect(for: rect) == rect)
    }
}
