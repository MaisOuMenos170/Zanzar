import Foundation
import Testing
@testable import ZanzarProject

@Suite("PasswordResetLink")
struct PasswordResetLinkTests {
    static let token = String(repeating: "aB3_-", count: 8) + "xyz" // 43 base64url characters

    private func link(_ string: String) -> PasswordResetLink? {
        PasswordResetLink(url: URL(string: string)!)
    }

    @Test("reads the token of the lero:// link")
    func appScheme() throws {
        let parsed = try #require(link("lero://reset-password?token=\(Self.token)"))
        #expect(parsed.token == Self.token)
        #expect(link("LERO://reset-password/?token=\(Self.token)")?.token == Self.token)
    }

    @Test(
        "ignores anything that is not a reset link",
        arguments: [
            "lero://other?token=\(PasswordResetLinkTests.token)",
            "lero://reset-password/extra?token=\(PasswordResetLinkTests.token)",
            "https://zanzarbackend-development.up.railway.app/reset-password?token=\(PasswordResetLinkTests.token)",
            "otherapp://reset-password?token=\(PasswordResetLinkTests.token)",
            "lero://reset-password",
            "lero://reset-password?token=short",
            "lero://reset-password?token=\(String(PasswordResetLinkTests.token.dropLast()))!",
            "lero://reset-password?code=\(PasswordResetLinkTests.token)"
        ]
    )
    func rejects(_ string: String) {
        #expect(link(string) == nil)
    }
}
