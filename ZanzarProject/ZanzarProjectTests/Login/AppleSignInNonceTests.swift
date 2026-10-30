import Foundation
import Testing
@testable import ZanzarProject

@Suite("AppleSignInNonce")
struct AppleSignInNonceTests {
    @Test("hashed is the lowercase SHA-256 hex of the raw value, the form the backend compares against")
    func hashedMatchesKnownDigest() {
        let nonce = AppleSignInNonce(raw: "abc")

        #expect(nonce.hashed == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
    }

    @Test("random nonces are unique and fit the backend's 256 character limit")
    func randomNoncesAreUnique() {
        let first = AppleSignInNonce.random()
        let second = AppleSignInNonce.random()

        #expect(first != second)
        #expect(first.raw.count == 64)
        #expect(first.raw.count <= 256)
    }
}
