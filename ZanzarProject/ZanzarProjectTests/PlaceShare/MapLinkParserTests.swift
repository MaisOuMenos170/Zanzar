// swiftlint:disable line_length
import Foundation
import Testing
@testable import ZanzarProject

@Suite("MapLinkParser")
struct MapLinkParserTests {
    private func hint(_ link: String) -> SharedPlaceHint {
        MapLinkParser.hint(from: URL(string: link)!)
    }

    // MARK: - Google Maps

    @Test("Google place link: name from the path, the pin (!3d!4d) over the viewport (@)")
    func googlePlaceWithPin() {
        let result = hint(
            "https://www.google.com/maps/place/Jardim+Bot%C3%A2nico+de+Curitiba/@-25.4423,-49.2397,17z/data=!3m1!4b1!4m6!3m5!8m2!3d-25.4421!4d-49.2395"
        )
        #expect(result.name == "Jardim Botânico de Curitiba")
        #expect(result.coordinate == SharedPlaceHint.Coordinate(latitude: -25.4421, longitude: -49.2395))
    }

    @Test("Google place link without a pin falls back to the viewport")
    func googlePlaceWithViewportOnly() {
        let result = hint("https://www.google.com/maps/place/Padaria+Central/@-25.43,-49.27,15z")
        #expect(result.name == "Padaria Central")
        #expect(result.coordinate == SharedPlaceHint.Coordinate(latitude: -25.43, longitude: -49.27))
    }

    @Test("Google place link whose \"name\" is the coordinates has no name")
    func googlePlaceNamedByCoordinates() {
        let result = hint("https://www.google.com/maps/place/-25.4284,-49.2733")
        #expect(result.name == nil)
        #expect(result.coordinate == SharedPlaceHint.Coordinate(latitude: -25.4284, longitude: -49.2733))
    }

    @Test("Google ?q= with coordinates")
    func googleQueryCoordinates() {
        let result = hint("https://www.google.com/maps?q=-25.4284,-49.2733")
        #expect(result.name == nil)
        #expect(result.coordinate == SharedPlaceHint.Coordinate(latitude: -25.4284, longitude: -49.2733))
    }

    @Test("Google ?q= with text, and the legacy host")
    func googleQueryText() {
        let result = hint("https://maps.google.com/?q=Rua+XV+de+Novembro,+100&ll=-25.4,-49.2")
        #expect(result.name == "Rua XV de Novembro, 100")
        #expect(result.coordinate == SharedPlaceHint.Coordinate(latitude: -25.4, longitude: -49.2))
    }

    @Test("Google search link (?api=1&query=)")
    func googleSearchQuery() {
        let result = hint("https://www.google.com/maps/search/?api=1&query=Parque+Barigui")
        #expect(result.name == "Parque Barigui")
        #expect(result.coordinate == nil)
    }

    @Test("Google search path")
    func googleSearchPath() {
        #expect(hint("https://www.google.com/maps/search/Parque+Tangu%C3%A1/@-25.38,-49.28,14z").name == "Parque Tanguá")
    }

    @Test("Google Brazil domain")
    func googleBrazilDomain() {
        #expect(hint("https://www.google.com.br/maps/place/Ópera+de+Arame/@-25.38,-49.27,17z").name == "Ópera de Arame")
    }

    // MARK: - Apple Maps

    @Test("Apple Maps ll + q")
    func appleLatLongAndQuery() {
        let result = hint("https://maps.apple.com/?ll=-25.4284,-49.2733&q=Jardim%20Bot%C3%A2nico")
        #expect(result.name == "Jardim Botânico")
        #expect(result.coordinate == SharedPlaceHint.Coordinate(latitude: -25.4284, longitude: -49.2733))
    }

    @Test("Apple Maps place with coordinate, name and address")
    func applePlace() {
        let result = hint(
            "https://maps.apple.com/place?coordinate=-25.4284,-49.2733&name=Padaria%20X&address=Rua%20XV%2C%20100%2C%20Curitiba"
        )
        #expect(result.name == "Padaria X")
        #expect(result.address == "Rua XV, 100, Curitiba")
        #expect(result.coordinate == SharedPlaceHint.Coordinate(latitude: -25.4284, longitude: -49.2733))
    }

    @Test("Apple Maps address only")
    func appleAddressOnly() {
        let result = hint("https://maps.apple.com/?address=Rua%20XV%2C%20100")
        #expect(result.name == nil)
        #expect(result.address == "Rua XV, 100")
    }

    // MARK: - Things that are not a place

    @Test("another site, a bare map link and out-of-range coordinates give nothing to go on")
    func nothingToGoOn() {
        #expect(hint("https://example.com/?q=Padaria&ll=-25.4,-49.2").isEmpty)
        #expect(hint("https://www.google.com/maps").isEmpty)
        #expect(hint("https://maps.apple.com/?ll=95,200").coordinate == nil)
        #expect(hint("https://www.google.com/maps?q=0,0").coordinate == nil)
    }

    // MARK: - Which links

    @Test("which links are map links and which are short")
    func linkKinds() {
        for link in ["https://maps.app.goo.gl/abc123", "https://goo.gl/maps/abc123", "https://maps.apple/p/abc"] {
            #expect(MapLinkParser.isShortLink(URL(string: link)!), "\(link)")
            #expect(MapLinkParser.isMapLink(URL(string: link)!), "\(link)")
        }
        for link in ["https://www.google.com/maps/place/X", "https://maps.apple.com/?q=X", "https://maps.google.com/?q=X"] {
            #expect(!MapLinkParser.isShortLink(URL(string: link)!), "\(link)")
            #expect(MapLinkParser.isMapLink(URL(string: link)!), "\(link)")
        }
        for link in ["https://example.com/maps/place/X", "https://www.google.com/search?q=X", "http://evilgoo.gl/maps/x",
                     "https://maps.app.goo.gl.evil.com/x"] {
            #expect(!MapLinkParser.isMapLink(URL(string: link)!), "\(link)")
        }
    }

    // MARK: - What was shared

    @Test("Google Maps shares name, address and a short link as text")
    func sharedTextWithLink() {
        let shared = MapLinkParser.read(
            texts: ["Padaria Central\nRua XV de Novembro, 100 - Centro\nhttps://maps.app.goo.gl/abc123"],
            urls: []
        )
        #expect(shared.mapURL == URL(string: "https://maps.app.goo.gl/abc123"))
        #expect(shared.lines == ["Padaria Central", "Rua XV de Novembro, 100 - Centro"])
    }

    @Test("a shared URL item wins over text, text around it is kept")
    func sharedURLItem() {
        let url = URL(string: "https://maps.apple.com/?ll=-25.4,-49.2&q=Padaria")!
        let shared = MapLinkParser.read(texts: ["Padaria"], urls: [url])
        #expect(shared.mapURL == url)
        #expect(shared.lines == ["Padaria"])
    }

    @Test("a link that is not a map link is ignored")
    func otherLinksIgnored() {
        let shared = MapLinkParser.read(texts: ["Olha isso https://example.com/x"], urls: [])
        #expect(shared.mapURL == nil)
        #expect(shared.lines == ["Olha isso"])
    }

    @Test("a plain address becomes the address to look up")
    func plainAddress() {
        let shared = MapLinkParser.read(texts: ["Rua XV de Novembro, 100\nCuritiba"], urls: [])
        let result = MapLinkParser.hint(link: shared.mapURL, lines: shared.lines)
        #expect(result.name == nil)
        #expect(result.address == "Rua XV de Novembro, 100, Curitiba")
        #expect(result.searchText == "Rua XV de Novembro, 100, Curitiba")
    }

    @Test("with a link, text lines only fill what the link did not say")
    func linesFillGaps() {
        let fromLink = MapLinkParser.hint(
            link: URL(string: "https://maps.app.goo.gl/abc")!,
            lines: ["Padaria Central", "Rua XV, 100"]
        )
        #expect(fromLink.name == "Padaria Central")
        #expect(fromLink.address == "Rua XV, 100")

        let linkWins = MapLinkParser.hint(
            link: URL(string: "https://maps.apple.com/?q=Padaria%20X&address=Rua%20Y")!,
            lines: ["Padaria Central", "Rua XV, 100"]
        )
        #expect(linkWins.name == "Padaria X")
        #expect(linkWins.address == "Rua Y")
    }

    @Test("search text is the name, else the address")
    func searchText() {
        #expect(SharedPlaceHint(name: "A", address: "B").searchText == "A")
        #expect(SharedPlaceHint(name: nil, address: "B").searchText == "B")
        #expect(SharedPlaceHint().searchText == nil)
    }
}

// swiftlint:enable line_length
