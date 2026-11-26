// swiftlint:disable line_length
import CoreLocation
import Foundation
import Testing
@testable import ZanzarProject

@MainActor
@Suite("PlaceShareViewModel")
struct PlaceShareViewModelTests {
    private static let appleLink = URL(string: "https://maps.apple.com/?ll=-25.4284,-49.2733&q=Padaria%20Central")!

    private static func place(_ name: String, latitude: Double, longitude: Double) -> SuggestedPlace {
        SuggestedPlace(name: name, address: "Rua XV, Curitiba", latitude: latitude, longitude: longitude)
    }

    private static let near = place("Padaria Central", latitude: -25.4285, longitude: -49.2733)
    private static let far = place("Padaria Central Filial", latitude: -25.4500, longitude: -49.2000)

    private func makeModel(
        texts: [String] = [],
        urls: [URL] = [],
        service: FakeShareService = FakeShareService(),
        fetcher: FakeRedirectFetcher = FakeRedirectFetcher(redirects: [:]),
        geocoder: FakeShareGeocoder = FakeShareGeocoder(),
        signedIn: Bool = true
    ) -> PlaceShareViewModel {
        PlaceShareViewModel(
            texts: texts,
            urls: urls,
            service: service,
            resolver: MapLinkResolver(fetcher: fetcher),
            geocoder: geocoder,
            isSignedIn: { signedIn }
        )
    }

    // MARK: - Reading

    @Test("signed out: says so and asks the backend nothing")
    func signedOut() async {
        let service = FakeShareService()
        let model = makeModel(urls: [Self.appleLink], service: service, signedIn: false)
        await model.load()
        #expect(model.phase == .signedOut)
        #expect(service.searches.isEmpty)
    }

    @Test("loading again does not undo a finished send")
    func loadRunsOnce() async {
        let service = FakeShareService(results: ["Padaria Central": [Self.near]])
        let model = makeModel(urls: [Self.appleLink], service: service)
        await model.load()
        await model.submit()
        await model.load()
        #expect(model.phase == .done(.success))
        #expect(service.searches.count == 1)
    }

    @Test("something that is not a place cannot be read")
    func unreadable() async {
        let model = makeModel(texts: ["https://example.com/x"], urls: [URL(string: "https://example.com/x")!])
        await model.load()
        #expect(model.phase == .unreadable)
    }

    @Test("a place outside the service area is refused before any search")
    func outsideArea() async {
        let service = FakeShareService()
        let saoPaulo = URL(string: "https://maps.apple.com/?ll=-23.5614,-46.6559&q=MASP")!
        let model = makeModel(urls: [saoPaulo], service: service)
        await model.load()
        #expect(model.phase == .outsideArea)
        #expect(service.searches.isEmpty)
    }

    // MARK: - Finding the place

    @Test("the place at the shared position is chosen, closest first, searched near the position")
    func choosesPlaceAtPosition() async {
        let service = FakeShareService(results: ["Padaria Central": [Self.far, Self.near]])
        let model = makeModel(urls: [Self.appleLink], service: service)
        await model.load()

        #expect(model.phase == .ready)
        #expect(model.candidates == [Self.near, Self.far])
        #expect(model.selectedPlace == Self.near)
        #expect(model.canSubmit)
        #expect(service.searches.first?.near?.latitude == -25.4284)
    }

    @Test("when nothing is at the shared position the person has to choose")
    func nothingNearLeavesChoiceToPerson() async {
        let service = FakeShareService(results: ["Padaria Central": [Self.far]])
        let model = makeModel(urls: [Self.appleLink], service: service)
        await model.load()

        #expect(model.selectedPlace == nil)
        #expect(!model.canSubmit)
        model.select(Self.far)
        #expect(model.canSubmit)
    }

    @Test("a plain address with a single match is chosen")
    func plainAddressSingleMatch() async {
        let service = FakeShareService(results: ["Rua XV de Novembro, 100": [Self.near]])
        let model = makeModel(texts: ["Rua XV de Novembro, 100"], service: service)
        await model.load()
        #expect(model.selectedPlace == Self.near)
    }

    @Test("a plain address with several matches is not guessed")
    func plainAddressManyMatches() async {
        let service = FakeShareService(results: ["Rua XV": [Self.near, Self.far]])
        let model = makeModel(texts: ["Rua XV"], service: service)
        await model.load()
        #expect(model.selectedPlace == nil)
        #expect(model.candidates.count == 2)
    }

    @Test("falls back to the address when the name finds nothing")
    func fallsBackToAddress() async {
        let link = URL(string: "https://maps.apple.com/place?coordinate=-25.4284,-49.2733&name=Padoca&address=Rua%20XV%2C%20100")!
        let service = FakeShareService(results: ["Rua XV, 100": [Self.near]])
        let model = makeModel(urls: [link], service: service)
        await model.load()

        #expect(service.searches.map(\.query) == ["Padoca", "Rua XV, 100"])
        #expect(model.selectedPlace == Self.near)
    }

    @Test("a short link is followed before reading it")
    func followsShortLink() async {
        let short = URL(string: "https://maps.app.goo.gl/abc")!
        let long = URL(string: "https://www.google.com/maps/place/Padaria+Central/@-25.4284,-49.2733,17z")!
        let service = FakeShareService(results: ["Padaria Central": [Self.near]])
        let model = makeModel(
            texts: ["Padaria Central\n\(short.absoluteString)"],
            service: service,
            fetcher: FakeRedirectFetcher(redirects: [short: long])
        )
        await model.load()
        #expect(model.selectedPlace == Self.near)
        #expect(service.searches.first?.near != nil)
    }

    @Test("a position with no name looks up its address and searches by it")
    func positionOnly() async {
        let link = URL(string: "https://www.google.com/maps?q=-25.4284,-49.2733")!
        let service = FakeShareService(results: ["Rua XV de Novembro, 100": [Self.near]])
        let model = makeModel(urls: [link], service: service, geocoder: FakeShareGeocoder(address: "Rua XV de Novembro, 100"))
        await model.load()
        #expect(model.hint.address == "Rua XV de Novembro, 100")
        #expect(model.selectedPlace == Self.near)
    }

    // MARK: - Sending

    @Test("nothing found: it goes for review with the address and the shared position")
    func manualWhenNothingFound() async {
        let service = FakeShareService()
        let model = makeModel(urls: [Self.appleLink], service: service)
        await model.load()
        #expect(model.isManualChosen)
        #expect(model.canSubmit)

        model.note = "  Muito bom  "
        await model.submit()

        #expect(model.phase == .done(.success))
        let sent = service.submitted.first
        #expect(sent?.location.latitude == -25.4284)
        #expect(sent?.location.address == "Padaria Central")
        #expect(sent?.note == "Muito bom")
    }

    @Test("a plain address nobody found is sent without a position")
    func manualWithoutPosition() async {
        let service = FakeShareService()
        let model = makeModel(texts: ["Rua das Flores, 10"], service: service)
        await model.load()
        await model.submit()
        #expect(service.submitted.first?.location == SuggestedLocation(latitude: 0, longitude: 0, address: "Rua das Flores, 10"))
    }

    @Test("a place found on the map is sent with its name, address and position")
    func sendsFoundPlace() async {
        let service = FakeShareService(results: ["Padaria Central": [Self.near]])
        let model = makeModel(urls: [Self.appleLink], service: service)
        await model.load()
        model.note = "Pão quentinho"
        await model.submit()

        #expect(model.phase == .done(.success))
        let sent = service.submitted.first
        #expect(sent?.name == "Padaria Central")
        #expect(sent?.location == SuggestedLocation(latitude: -25.4285, longitude: -49.2733, address: "Rua XV, Curitiba"))
        #expect(sent?.note == "Pão quentinho")
    }

    @Test("choosing \"none of these\" sends the shared address and position instead of the found place")
    func chooseManualInstead() async {
        let service = FakeShareService(results: ["Padaria Central": [Self.near]])
        let model = makeModel(urls: [Self.appleLink], service: service)
        await model.load()
        model.chooseManual()
        await model.submit()

        #expect(service.submitted.count == 1)
        #expect(service.submitted.first?.location.address == "Padaria Central")
        #expect(service.submitted.first?.location.latitude == -25.4284)
    }

    @Test("a failed send stays on the sheet with a message, so it can be tried again")
    func failedSend() async {
        let service = FakeShareService(results: ["Padaria Central": [Self.near]])
        service.submitError = APIError.rateLimited(retryAfter: 60)
        let model = makeModel(urls: [Self.appleLink], service: service)
        await model.load()
        await model.submit()

        #expect(model.phase == .ready)
        #expect(model.submitErrorMessage != nil)
        #expect(model.canSubmit)
    }

    @Test("a refused session while sending asks to sign in")
    func expiredSessionWhileSending() async {
        let service = FakeShareService(results: ["Padaria Central": [Self.near]])
        service.submitError = APIError.httpStatus(401, message: nil)
        let model = makeModel(urls: [Self.appleLink], service: service)
        await model.load()
        await model.submit()
        #expect(model.phase == .signedOut)
    }

    @Test("a search that fails still lets the place go for review")
    func searchFailureKeepsManual() async {
        let service = FakeShareService()
        service.searchError = APIError.rateLimited(retryAfter: 30)
        let model = makeModel(urls: [Self.appleLink], service: service)
        await model.load()

        #expect(model.searchErrorMessage != nil)
        #expect(model.phase == .ready)
        #expect(model.isManualChosen)
    }
}

final class FakeShareService: PlaceSuggestionServicing, @unchecked Sendable {
    struct Search: Equatable {
        let query: String
        let near: SuggestedLocation?
    }

    private let results: [String: [SuggestedPlace]]
    var searchError: Error?
    var submitError: Error?
    private(set) var searches: [Search] = []
    private(set) var submitted: [PlaceSuggestion] = []

    init(results: [String: [SuggestedPlace]] = [:]) {
        self.results = results
    }

    func currentLocation() async throws -> SuggestedLocation { throw CancellationError() }
    func fetchMine() async throws -> [MySuggestion] { [] }

    func searchPlaces(query: String, near: SuggestedLocation?) async throws -> [SuggestedPlace] {
        searches.append(Search(query: query, near: near))
        if let searchError { throw searchError }
        return results[query] ?? []
    }

    func resolveAddress(_ text: String, near: SuggestedLocation?) async throws -> SuggestedPlace? { nil }

    func submit(_ suggestion: PlaceSuggestion) async throws -> PlaceSuggestionOutcome {
        if let submitError { throw submitError }
        submitted.append(suggestion)
        return .success
    }
}

final class FakeShareGeocoder: PlaceGeocoding, @unchecked Sendable {
    private let address: String?

    init(address: String? = nil) {
        self.address = address
    }

    func address(for coordinate: CLLocationCoordinate2D) async throws -> String? { address }

    func places(
        matching query: String,
        near: CLLocationCoordinate2D?,
        includingPointsOfInterest: Bool
    ) async throws -> [SuggestedPlace] { [] }
}

// swiftlint:enable line_length
