import Testing

@testable import ZanzarProject

@Suite("PhotoRetryPolicy")
struct PhotoRetryPolicyTests {
    @Test("the first failure waits 2 seconds and the second waits 4")
    func delays() {
        #expect(PhotoRetryPolicy.delay(afterFailedAttempts: 1) == .seconds(2))
        #expect(PhotoRetryPolicy.delay(afterFailedAttempts: 2) == .seconds(4))
    }

    @Test("it gives up once the retries are used up")
    func givesUp() {
        #expect(PhotoRetryPolicy.delay(afterFailedAttempts: 3) == nil)
        #expect(PhotoRetryPolicy.delay(afterFailedAttempts: 10) == nil)
    }

    @Test("a count that is not a failure never schedules a retry")
    func ignoresInvalidCounts() {
        #expect(PhotoRetryPolicy.delay(afterFailedAttempts: 0) == nil)
        #expect(PhotoRetryPolicy.delay(afterFailedAttempts: -1) == nil)
    }
}
