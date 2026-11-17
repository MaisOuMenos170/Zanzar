import Foundation
import Testing
@testable import ZanzarProject

@Suite("JWTDecoder")
struct JWTDecoderTests {
    /// A token as the backend sends it: base64url without padding.
    private func token(payload: String) -> String {
        let encoded = Data(payload.utf8).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        return "header.\(encoded).signature"
    }

    @Test("reads the user id from the id claim")
    func readsID() {
        #expect(JWTDecoder.userID(from: token(payload: #"{"id":"abc123"}"#)) == "abc123")
    }

    @Test("handles payloads whose length is not a multiple of 4 (padding stripped)")
    func handlesMissingPadding() {
        for id in ["a", "ab", "abc", "abcd", "abcde"] {
            #expect(JWTDecoder.userID(from: token(payload: #"{"id":"\#(id)"}"#)) == id)
        }
    }

    @Test("falls back to sub when there is no id")
    func fallsBackToSub() {
        #expect(JWTDecoder.userID(from: token(payload: #"{"sub":"from-sub"}"#)) == "from-sub")
    }

    @Test("prefers id over sub")
    func prefersID() {
        #expect(JWTDecoder.userID(from: token(payload: #"{"id":"the-id","sub":"the-sub"}"#)) == "the-id")
    }

    @Test("returns nil for tokens it cannot read")
    func returnsNilForGarbage() {
        #expect(JWTDecoder.userID(from: "") == nil)
        #expect(JWTDecoder.userID(from: "onlyonesegment") == nil)
        #expect(JWTDecoder.userID(from: "header.!!!not-base64!!!.signature") == nil)
        #expect(JWTDecoder.userID(from: token(payload: "[1,2,3]")) == nil)
        #expect(JWTDecoder.userID(from: token(payload: #"{"id":42}"#)) == nil)
        #expect(JWTDecoder.userID(from: token(payload: #"{"name":"no id"}"#)) == nil)
    }
}
