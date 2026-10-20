import Foundation
import Testing
@testable import ZanzarProject

@Suite("APIError rate limit")
struct APIErrorTests {
    @Test("a short wait asks the user to try again in a moment")
    func shortWait() {
        #expect(APIError.rateLimited(retryAfter: 20).errorDescription == String(localized: "error.rateLimited.soon"))
        #expect(APIError.rateLimited(retryAfter: 30).errorDescription == String(localized: "error.rateLimited.soon"))
    }

    @Test("a longer wait is rounded up to whole minutes")
    func minutesRoundUp() {
        #expect(
            APIError.rateLimited(retryAfter: 31).errorDescription
                == String(localized: "error.rateLimited.message \(1)")
        )
        #expect(
            APIError.rateLimited(retryAfter: 61).errorDescription
                == String(localized: "error.rateLimited.message \(2)")
        )
        #expect(
            APIError.rateLimited(retryAfter: 900).errorDescription
                == String(localized: "error.rateLimited.message \(15)")
        )
    }

    @Test("rateLimitedMessage only answers for rate limit errors")
    func rateLimitedMessageIsSpecific() {
        let rateLimited = APIError.rateLimited(retryAfter: 120)

        #expect(APIError.rateLimitedMessage(for: rateLimited) == rateLimited.errorDescription)
        #expect(APIError.rateLimitedMessage(for: APIError.httpStatus(500, message: "boom")) == nil)
        #expect(APIError.rateLimitedMessage(for: URLError(.notConnectedToInternet)) == nil)
    }
}
