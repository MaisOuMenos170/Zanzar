import Foundation

/// Runs `operation` and gives up after `limit` by throwing `timeoutError`; the operation is cancelled then.
/// An operation that finishes (or throws) first wins, and the timer is cancelled.
nonisolated func withTimeout<T: Sendable>(
    _ limit: Duration,
    throwing timeoutError: any Error,
    operation: @escaping @Sendable () async throws -> T
) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask { try await operation() }
        group.addTask {
            try await Task.sleep(for: limit)
            throw timeoutError
        }
        defer { group.cancelAll() }
        guard let first = try await group.next() else { throw CancellationError() }
        return first
    }
}
