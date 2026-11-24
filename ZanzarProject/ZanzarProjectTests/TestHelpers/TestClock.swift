import Foundation
import os

/// A hand-moved clock for freshness-window and `Retry-After` tests; `date` is what the code under test
/// sees as "now". Lock-backed so it can also be captured by `@Sendable` clocks.
final class TestClock: Sendable {
    private let state: OSAllocatedUnfairLock<Date>

    init(_ date: Date = Date(timeIntervalSince1970: 0)) {
        state = OSAllocatedUnfairLock(initialState: date)
    }

    var date: Date {
        state.withLock { $0 }
    }

    func advance(by seconds: TimeInterval) {
        state.withLock { $0 = $0.addingTimeInterval(seconds) }
    }
}
