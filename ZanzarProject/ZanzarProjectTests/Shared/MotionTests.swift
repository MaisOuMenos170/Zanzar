import Testing
@testable import ZanzarProject

struct MotionTests {
    @Test func stampSizeDurationsMatchTheShippedStamps() {
        #expect(Motion.StampSize.small.duration == 0.35)
        #expect(Motion.StampSize.medium.duration == 0.45)
        #expect(Motion.StampSize.large.duration == 0.62)
    }
}
