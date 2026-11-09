import Foundation

/// Decodes to `nil` instead of throwing, so one malformed element of a list does not fail the whole response.
nonisolated struct FailableDecodable<Value: Decodable & Sendable>: Decodable, Sendable {
    let value: Value?

    init(from decoder: Decoder) throws {
        value = try? Value(from: decoder)
    }
}
