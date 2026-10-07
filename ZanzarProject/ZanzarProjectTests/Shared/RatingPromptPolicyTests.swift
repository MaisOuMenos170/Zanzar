import Foundation
import Testing
@testable import ZanzarProject

@Suite("RatingPromptPolicy")
struct RatingPromptPolicyTests {
    @Test("uses a six-hour validity window")
    func validityWindow() {
        #expect(RatingPromptPolicy.validityWindow == 6 * 60 * 60)
    }

    @Test("uses a 150 meter leave distance")
    func leaveDistance() {
        #expect(RatingPromptPolicy.leaveDistance == 150)
    }
}
