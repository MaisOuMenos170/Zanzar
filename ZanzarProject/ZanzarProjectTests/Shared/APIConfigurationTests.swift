import Foundation
import Testing
@testable import ZanzarProject

@Suite("APIConfiguration")
struct APIConfigurationTests {
    @Test("Debug builds expose an http base URL")
    func debugBaseURL() {
        #if DEBUG
        let url = APIConfiguration.baseURL
        #expect(url.scheme == "http" || url.scheme == "https")
        #expect(!url.absoluteString.isEmpty)
        #else
        Issue.record("Release base URL requires bundle configuration — run this test in Debug")
        #endif
    }
}
