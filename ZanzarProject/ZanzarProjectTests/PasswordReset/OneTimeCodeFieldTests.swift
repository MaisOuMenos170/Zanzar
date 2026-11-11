import Testing
@testable import ZanzarProject

@MainActor
@Suite("OneTimeCodeField")
struct OneTimeCodeFieldTests {
    @Test("shows each typed digit in its own box and leaves the rest empty")
    func digitsFillBoxesInOrder() {
        let boxes = (0..<6).map { OneTimeCodeField.digit(at: $0, in: "159") }

        #expect(boxes == ["1", "5", "9", "", "", ""])
    }

    @Test("an empty code leaves every box empty")
    func emptyCode() {
        let boxes = (0..<6).map { OneTimeCodeField.digit(at: $0, in: "") }

        #expect(boxes == Array(repeating: "", count: 6))
    }

    @Test("an index outside the code gives an empty box")
    func outOfRangeIndex() {
        #expect(OneTimeCodeField.digit(at: -1, in: "123456") == "")
        #expect(OneTimeCodeField.digit(at: 6, in: "123456") == "")
    }
}
