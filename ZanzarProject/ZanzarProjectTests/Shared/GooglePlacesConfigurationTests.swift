import Foundation
import Testing
@testable import ZanzarProject

@Suite("GooglePlacesConfiguration")
struct GooglePlacesConfigurationTests {
    @Test("builds a backend photo proxy URL with ref and maxwidth")
    func photoURLUsesBackendProxy() throws {
        let url = try #require(GooglePlacesConfiguration.photoURL(reference: "AUacSh123", maxWidth: 400))
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))

        #expect(components.path.hasSuffix("places/photo"))
        #expect(components.queryItems?.contains(URLQueryItem(name: "ref", value: "AUacSh123")) == true)
        #expect(components.queryItems?.contains(URLQueryItem(name: "maxwidth", value: "400")) == true)
        #expect(components.queryItems?.contains(where: { $0.name == "key" }) == false)
    }

    @Test("defaults maxwidth to 800")
    func defaultMaxWidth() throws {
        let url = try #require(GooglePlacesConfiguration.photoURL(reference: "ref"))
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))

        #expect(components.queryItems?.contains(URLQueryItem(name: "maxwidth", value: "800")) == true)
    }
}
