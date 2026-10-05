import Foundation
import Testing
@testable import ZanzarProject

@Suite("PlaceDetail navigation apps")
struct PlaceDetailNavigationAppTests {
    @Test("Apple Maps URL encodes the place name and keeps negative coordinates")
    func appleMapsURL() throws {
        let url = try #require(
            PlaceDetailNavigationApp.appleMaps.directionsURL(
                latitude: -25.41,
                longitude: -49.27,
                placeName: "Bar & Grill #1"
            )
        )
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))

        #expect(components.host == "maps.apple.com")
        #expect(components.queryItems?.first { $0.name == "daddr" }?.value == "-25.41,-49.27")
        #expect(components.queryItems?.first { $0.name == "q" }?.value == "Bar & Grill #1")
        #expect(!url.absoluteString.contains("Bar & Grill"))
    }

    @Test("Google Maps URL uses the comgooglemaps scheme with the destination")
    func googleMapsURL() throws {
        let url = try #require(
            PlaceDetailNavigationApp.googleMaps.directionsURL(latitude: -25.41, longitude: -49.27, placeName: "Museu")
        )
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))

        #expect(components.scheme == "comgooglemaps")
        #expect(components.queryItems?.first { $0.name == "daddr" }?.value == "-25.41,-49.27")
    }

    @Test("Waze URL uses the waze scheme and starts navigation")
    func wazeURL() throws {
        let url = try #require(
            PlaceDetailNavigationApp.waze.directionsURL(latitude: -25.41, longitude: -49.27, placeName: "Museu")
        )
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))

        #expect(components.scheme == "waze")
        #expect(components.queryItems?.first { $0.name == "ll" }?.value == "-25.41,-49.27")
        #expect(components.queryItems?.first { $0.name == "navigate" }?.value == "yes")
    }
}
