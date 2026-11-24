import Foundation
import Testing
@testable import ZanzarProject

@Suite("withTimeout")
struct WithTimeoutTests {
    private enum Failure: Error, Equatable {
        case timedOut
        case operationFailed
    }

    @Test("returns the value of an operation that finishes in time")
    func returnsTheValue() async throws {
        let value = try await withTimeout(.seconds(5), throwing: Failure.timedOut) { 7 }

        #expect(value == 7)
    }

    @Test("gives up on an operation that never finishes and throws the given error")
    func throwsTheTimeoutError() async {
        await #expect(throws: Failure.timedOut) {
            try await withTimeout(.milliseconds(50), throwing: Failure.timedOut) {
                try await Task.sleep(for: .seconds(60))
                return 1
            }
        }
    }

    @Test("passes on the error of an operation that fails before the timeout")
    func passesOnTheOperationError() async {
        await #expect(throws: Failure.operationFailed) {
            try await withTimeout(.seconds(5), throwing: Failure.timedOut) { () async throws -> Int in
                throw Failure.operationFailed
            }
        }
    }

    @Test("cancelling the caller cancels the operation")
    func cancellationPropagates() async {
        let task = Task {
            try await withTimeout(.seconds(30), throwing: Failure.timedOut) {
                try await Task.sleep(for: .seconds(60))
                return 1
            }
        }
        task.cancel()

        await #expect(throws: CancellationError.self) {
            try await task.value
        }
    }
}
