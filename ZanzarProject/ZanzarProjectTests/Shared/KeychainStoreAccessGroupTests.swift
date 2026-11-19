import Testing
@testable import ZanzarProject

@Suite("KeychainStore access group")
struct KeychainStoreAccessGroupTests {
    @Test("an expanded group is used")
    func usesExpandedGroup() {
        #expect(KeychainStore.accessGroup(from: "982D3NRR89.dalpra.Zanzar") == "982D3NRR89.dalpra.Zanzar")
    }

    @Test("a missing, empty or unexpanded group leaves the attribute out")
    func ignoresUnusableValues() {
        #expect(KeychainStore.accessGroup(from: nil) == nil)
        #expect(KeychainStore.accessGroup(from: "") == nil)
        #expect(KeychainStore.accessGroup(from: "$(AppIdentifierPrefix)dalpra.Zanzar") == nil)
        #expect(KeychainStore.accessGroup(from: 42) == nil)
    }
}
