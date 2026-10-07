import Foundation
import Testing
@testable import ZanzarProject

@Suite("PlaceCategorySealState")
struct PlaceCategorySealStateTests {
    @Test("exposes preview and earned cases")
    func casesExist() {
        let preview: PlaceCategorySealState = .preview
        let earned: PlaceCategorySealState = .earned

        if case .preview = preview {} else { Issue.record("Expected preview case") }
        if case .earned = earned {} else { Issue.record("Expected earned case") }
    }
}
