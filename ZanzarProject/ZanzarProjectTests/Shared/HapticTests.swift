import SwiftUI
import Testing
@testable import ZanzarProject

struct HapticTests {
    @Test func carimboKeepsShippedIntensity() {
        #expect(Haptic.carimbo.feedback == .impact(flexibility: .rigid, intensity: 0.7))
    }

    @Test func carimboLeveKeepsShippedIntensity() {
        #expect(Haptic.carimboLeve.feedback == .impact(flexibility: .rigid, intensity: 0.55))
    }
}
