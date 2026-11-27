import Foundation
import Testing
@testable import ZanzarProject

@Suite("APIError rate limit")
struct APIErrorTests {
    @Test("a short wait asks the user to try again in a moment")
    func shortWait() {
        #expect(APIError.rateLimited(retryAfter: 20).errorDescription == L10n.string("error.rateLimited.soon"))
        #expect(APIError.rateLimited(retryAfter: 30).errorDescription == L10n.string("error.rateLimited.soon"))
    }

    @Test("a longer wait is rounded up to whole minutes")
    func minutesRoundUp() {
        #expect(
            APIError.rateLimited(retryAfter: 31).errorDescription
                == L10n.string("error.rateLimited.message", 1)
        )
        #expect(
            APIError.rateLimited(retryAfter: 61).errorDescription
                == L10n.string("error.rateLimited.message", 2)
        )
        #expect(
            APIError.rateLimited(retryAfter: 900).errorDescription
                == L10n.string("error.rateLimited.message", 15)
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

@Suite("APIError display message")
struct APIErrorDisplayMessageTests {
    private let fallback = "fallback"

    @Test("an answer without text, or one that cannot be read, shows the fallback, never the system text")
    func fallbackWhenThereIsNoText() {
        let errors: [Error] = [
            APIError.httpStatus(500, message: nil),
            APIError.decodingFailed,
            APIError.invalidResponse,
            APIError.invalidRequest
        ]
        for error in errors {
            #expect(APIError.displayMessage(for: error, fallback: fallback) == fallback)
        }
    }

    @Test("the server's text and the rate limit text come through")
    func keepsTheTextWhenThereIsOne() {
        let refused = APIError.httpStatus(400, message: "Bad name")
        #expect(APIError.displayMessage(for: refused, fallback: fallback) == "Bad name")
        let limited = APIError.rateLimited(retryAfter: 600)
        #expect(APIError.displayMessage(for: limited, fallback: fallback) == limited.errorDescription)
    }

    @Test("an error that is not an APIError keeps the system's own (localized) text")
    func otherErrorsKeepTheirDescription() {
        let error = URLError(.notConnectedToInternet)
        #expect(APIError.displayMessage(for: error, fallback: fallback) == error.localizedDescription)
    }
}

@Suite("URLError offline")
struct URLErrorOfflineTests {
    @Test("the errors that mean 'no network now' are offline, the others are not")
    func offlineCodes() {
        for code: URLError.Code in [.notConnectedToInternet, .networkConnectionLost, .timedOut, .cannotConnectToHost] {
            #expect(URLError(code).isOffline)
            #expect((URLError(code) as Error).isOffline)
        }
        #expect(!URLError(.badURL).isOffline)
        #expect(!URLError(.cancelled).isOffline)
        #expect(!(APIError.httpStatus(500, message: nil) as Error).isOffline)
    }
}
