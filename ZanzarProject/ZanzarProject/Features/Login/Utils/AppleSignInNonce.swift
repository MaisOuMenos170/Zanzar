import CryptoKit
import Foundation

/// Replay protection for Sign in with Apple: Apple gets the SHA-256 (`hashed`) and embeds it in the
/// identity token, the backend gets the `raw` value and checks it against that claim.
nonisolated struct AppleSignInNonce: Sendable, Equatable {
    let raw: String

    var hashed: String {
        SHA256.hash(data: Data(raw.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
    }

    static func random() -> AppleSignInNonce {
        var generator = SystemRandomNumberGenerator()
        let bytes = (0..<32).map { _ in UInt8.random(in: .min ... .max, using: &generator) }
        return AppleSignInNonce(raw: bytes.map { String(format: "%02x", $0) }.joined())
    }
}
