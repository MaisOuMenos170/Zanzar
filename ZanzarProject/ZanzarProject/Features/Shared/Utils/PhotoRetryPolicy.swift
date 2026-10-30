import Foundation

/// When a place photo that failed to load is requested again.
nonisolated enum PhotoRetryPolicy {
    static let maximumRetries = 2

    /// How long to wait before retrying after the given number of failed attempts (1 = the first failure).
    /// `nil` once the retries are used up. Waits 2 s, then 4 s.
    static func delay(afterFailedAttempts failedAttempts: Int) -> Duration? {
        guard (1...maximumRetries).contains(failedAttempts) else { return nil }
        return .seconds(1 << failedAttempts)
    }
}
