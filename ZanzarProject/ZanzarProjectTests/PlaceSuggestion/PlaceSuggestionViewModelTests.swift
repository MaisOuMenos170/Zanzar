import Foundation
import Testing
@testable import ZanzarProject

@MainActor
@Suite("PlaceSuggestionViewModel")
struct PlaceSuggestionViewModelTests {
    private static let home = SuggestedLocation(
        latitude: -25.43,
        longitude: -49.27,
        address: "Rua XV de Novembro, 1200"
    )

    private func makeViewModel(
        service: MockPlaceSuggestionService = MockPlaceSuggestionService()
    ) -> PlaceSuggestionViewModel {
        PlaceSuggestionViewModel(service: service)
    }

    private static let garden = SuggestedPlace(
        osmType: "way",
        osmID: 42,
        name: "Jardim Botânico",
        address: "Rua Engenheiro Ostoja Roguski, Curitiba",
        latitude: -25.44,
        longitude: -49.24
    )

    private func makeViewModelWithResults(service: MockPlaceSuggestionService) async -> PlaceSuggestionViewModel {
        service.searchResult = .success([Self.garden])
        let viewModel = makeViewModel(service: service)
        viewModel.query = "jardim"
        await viewModel.search()
        return viewModel
    }

    @Test("the button stays disabled until a place is chosen and the reason is filled")
    func cannotSubmitWithoutPlaceAndNote() async {
        let viewModel = await makeViewModelWithResults(service: MockPlaceSuggestionService())

        #expect(!viewModel.canSubmit)

        viewModel.select(Self.garden)
        #expect(!viewModel.canSubmit)

        viewModel.note = "   "
        #expect(!viewModel.canSubmit)

        viewModel.note = "O jardim de inverno é lindo"
        #expect(viewModel.canSubmit)
    }

    @Test("searching needs at least two letters and is limited like the backend")
    func searchLimits() {
        let viewModel = makeViewModel()
        #expect(!viewModel.canSearch)

        viewModel.query = " a "
        #expect(!viewModel.canSearch)

        viewModel.query = "ja"
        #expect(viewModel.canSearch)

        viewModel.query = String(repeating: "x", count: PlaceSuggestionLimits.queryMaxLength + 1)
        #expect(!viewModel.canSearch)
    }

    @Test("a search sends the trimmed text and, when asked, the user's position")
    func searchSendsQueryAndLocation() async {
        let service = MockPlaceSuggestionService()
        let viewModel = makeViewModel(service: service)
        await viewModel.loadCurrentLocation()
        viewModel.query = "  jardim  "

        await viewModel.search()

        #expect(service.searches == [.init(query: "jardim", near: Self.home)])
        #expect(viewModel.hasSearched)
    }

    @Test("with the near-me option off, the position is not looked up or sent")
    func searchWithoutLocation() async {
        let service = MockPlaceSuggestionService()
        let viewModel = makeViewModel(service: service)
        viewModel.searchNearMe = false

        await viewModel.loadCurrentLocation()
        viewModel.query = "jardim"
        await viewModel.search()

        #expect(service.currentLocationCalls == 0)
        #expect(service.searches == [.init(query: "jardim", near: nil)])
    }

    @Test("a new search clears the chosen place and the manual choice")
    func searchResetsSelection() async {
        let viewModel = await makeViewModelWithResults(service: MockPlaceSuggestionService())
        viewModel.select(Self.garden)
        viewModel.enterManually()

        await viewModel.search()

        #expect(viewModel.selectedPlace == nil)
        #expect(!viewModel.isManualEntry)
    }

    @Test("a failed search shows its message and keeps the form")
    func searchFailure() async {
        let service = MockPlaceSuggestionService()
        service.searchResult = .failure(APIError.rejected(503, code: "osm_unavailable", message: nil))
        let viewModel = makeViewModel(service: service)
        viewModel.query = "jardim"

        await viewModel.search()

        #expect(viewModel.searchErrorMessage == L10n.string("placeSuggestion.error.osmUnavailable"))
        #expect(viewModel.results.isEmpty)
        #expect(!viewModel.hasSearched)
        #expect(!viewModel.isSearching)
    }

    @Test("choosing to send what was typed needs the typed text and the reason")
    func manualEntryNeedsQueryAndNote() {
        let viewModel = makeViewModel()
        viewModel.note = "Vale a pena"
        viewModel.enterManually()
        #expect(!viewModel.canSubmit)

        viewModel.query = "Restaurante Spaghetto"
        #expect(viewModel.canSubmit)

        viewModel.query = String(repeating: "y", count: PlaceSuggestionLimits.addressMaxLength + 1)
        #expect(!viewModel.canSubmit)
    }

    @Test("a reason over the backend limit blocks the button")
    func noteLimitBlocksSubmit() async {
        let viewModel = await makeViewModelWithResults(service: MockPlaceSuggestionService())
        viewModel.select(Self.garden)
        viewModel.note = String(repeating: "x", count: PlaceSuggestionLimits.noteMaxLength + 1)
        #expect(!viewModel.canSubmit)

        viewModel.note = String(repeating: "x", count: PlaceSuggestionLimits.noteMaxLength)
        #expect(viewModel.canSubmit)
    }

    @Test("a position that is already known is not looked up again")
    func loadsOnce() async {
        let service = MockPlaceSuggestionService()
        let viewModel = makeViewModel(service: service)

        await viewModel.loadCurrentLocation()
        await viewModel.loadCurrentLocation()

        #expect(service.currentLocationCalls == 1)
    }

    @Test("a denied permission shows its message and a later attempt can recover")
    func deniedPermissionThenRetry() async {
        let service = MockPlaceSuggestionService()
        service.currentLocationResult = .failure(LocationMapError.authorizationDenied)
        let viewModel = makeViewModel(service: service)

        await viewModel.loadCurrentLocation()

        #expect(viewModel.currentLocation == nil)
        #expect(viewModel.locationErrorMessage == L10n.string("placeSuggestion.error.locationDenied"))

        service.currentLocationResult = .success(Self.home)
        await viewModel.loadCurrentLocation()

        #expect(viewModel.currentLocation == Self.home)
        #expect(viewModel.locationErrorMessage == nil)
    }

}

extension PlaceSuggestionViewModelTests {
    @Test("a place that goes straight into the app is told as published")
    func submitPublished() async {
        let service = MockPlaceSuggestionService()
        service.submitPlaceResult = .success(Self.suggestion(status: .approved, name: "Jardim Botânico"))
        let viewModel = await makeViewModelWithResults(service: service)
        viewModel.select(Self.garden)
        viewModel.note = "  O jardim de inverno é lindo \n"

        let succeeded = await viewModel.submit()

        #expect(succeeded)
        #expect(viewModel.outcome == .published(placeName: "Jardim Botânico"))
        #expect(!viewModel.isSubmitting)
        #expect(service.submittedPlaces == [.init(place: Self.garden, note: "O jardim de inverno é lindo")])
    }

    @Test("a place held for the team is told as under review")
    func submitUnderReview() async {
        let service = MockPlaceSuggestionService()
        service.submitPlaceResult = .success(Self.suggestion(status: .needsReview, name: "Jardim Botânico"))
        let viewModel = await makeViewModelWithResults(service: service)
        viewModel.select(Self.garden)
        viewModel.note = "Vale a pena"

        await viewModel.submit()

        #expect(viewModel.outcome == .success)
    }

    @Test("a place the check refused is told with its reason")
    func submitRefused() async {
        let service = MockPlaceSuggestionService()
        service.submitPlaceResult = .success(
            Self.suggestion(status: .rejected, name: "Jardim Botânico", reason: .duplicate)
        )
        let viewModel = await makeViewModelWithResults(service: service)
        viewModel.select(Self.garden)
        viewModel.note = "Vale a pena"

        await viewModel.submit()

        #expect(viewModel.outcome == .refused(.duplicate))
    }

    @Test("sending what was typed goes to the team with the position when it is known")
    func submitManual() async {
        let service = MockPlaceSuggestionService()
        let viewModel = makeViewModel(service: service)
        await viewModel.loadCurrentLocation()
        viewModel.query = "  Restaurante Spaghetto "
        viewModel.enterManually()
        viewModel.note = "A comida é muito boa"

        let succeeded = await viewModel.submit()

        #expect(succeeded)
        #expect(viewModel.outcome == .success)
        let expected = PlaceSuggestion(
            location: SuggestedLocation(latitude: -25.43, longitude: -49.27, address: "Restaurante Spaghetto"),
            note: "A comida é muito boa"
        )
        #expect(service.submitted == [expected])
    }

    @Test("sending what was typed without a position uses zero coordinates")
    func submitManualWithoutLocation() async {
        let service = MockPlaceSuggestionService()
        let viewModel = makeViewModel(service: service)
        viewModel.searchNearMe = false
        viewModel.query = "Restaurante Spaghetto"
        viewModel.enterManually()
        viewModel.note = "A comida é muito boa"

        await viewModel.submit()

        let expected = PlaceSuggestion(
            location: SuggestedLocation(latitude: 0, longitude: 0, address: "Restaurante Spaghetto"),
            note: "A comida é muito boa"
        )
        #expect(service.submitted == [expected])
    }

    @Test("a server failure keeps the form and shows an error")
    func submitServerFailure() async {
        let service = MockPlaceSuggestionService()
        service.submitPlaceResult = .failure(APIError.httpStatus(500, message: nil))
        let viewModel = await makeViewModelWithResults(service: service)
        viewModel.select(Self.garden)
        viewModel.note = "Vale a pena"

        let succeeded = await viewModel.submit()

        #expect(!succeeded)
        #expect(viewModel.outcome == .failure(message: L10n.string("placeSuggestion.error.generic")))
        #expect(viewModel.note == "Vale a pena")
        #expect(!viewModel.isSubmitting)
    }

    @Test("a 400 from the backend gets its own message")
    func submitValidationFailure() async {
        let service = MockPlaceSuggestionService()
        service.submitPlaceResult = .failure(APIError.httpStatus(400, message: "invalid"))
        let viewModel = await makeViewModelWithResults(service: service)
        viewModel.select(Self.garden)
        viewModel.note = "Vale a pena"

        await viewModel.submit()

        #expect(viewModel.outcome == .failure(message: L10n.string("placeSuggestion.error.invalid")))
    }

    @Test("a place the server cannot find gets its own message")
    func submitNotFound() async {
        let service = MockPlaceSuggestionService()
        service.submitPlaceResult = .failure(APIError.rejected(404, code: "place_not_found", message: nil))
        let viewModel = await makeViewModelWithResults(service: service)
        viewModel.select(Self.garden)
        viewModel.note = "Vale a pena"

        await viewModel.submit()

        #expect(viewModel.outcome == .failure(message: L10n.string("placeSuggestion.error.notFound")))
    }

    @Test("a cancelled request is not reported as an error")
    func submitCancellationIsSilent() async {
        let service = MockPlaceSuggestionService()
        service.submitPlaceResult = .failure(URLError(.cancelled))
        let viewModel = await makeViewModelWithResults(service: service)
        viewModel.select(Self.garden)
        viewModel.note = "Vale a pena"

        let succeeded = await viewModel.submit()

        #expect(!succeeded)
        #expect(viewModel.outcome == nil)
    }

    @Test("submitting is ignored while the form is not valid")
    func submitIgnoredWhenInvalid() async {
        let service = MockPlaceSuggestionService()
        let viewModel = makeViewModel(service: service)

        let succeeded = await viewModel.submit()

        #expect(!succeeded)
        #expect(service.submitted.isEmpty)
        #expect(service.submittedPlaces.isEmpty)
    }

    nonisolated static func suggestion(
        status: PlaceSuggestionStatus,
        name: String? = nil,
        reason: PlaceSuggestionDecisionReason? = nil
    ) -> MySuggestion {
        MySuggestion(
            id: "s1",
            status: status,
            name: name,
            address: "Rua A",
            note: nil,
            decisionReason: reason,
            placeID: nil,
            createdAt: Date(timeIntervalSince1970: 1_000),
            decidedAt: nil
        )
    }
}

final class MockPlaceSuggestionService: PlaceSuggestionServicing, @unchecked Sendable {
    struct Search: Equatable {
        let query: String
        let near: SuggestedLocation?
    }

    struct SubmittedPlace: Equatable {
        let place: SuggestedPlace
        let note: String
    }

    var currentLocationResult: Result<SuggestedLocation, Error> = .success(
        SuggestedLocation(latitude: -25.43, longitude: -49.27, address: "Rua XV de Novembro, 1200")
    )
    var submitResult: Result<Void, Error> = .success(())
    var searchResult: Result<[SuggestedPlace], Error> = .success([])
    var submitPlaceResult: Result<MySuggestion, Error> = .success(
        PlaceSuggestionViewModelTests.suggestion(status: .needsReview)
    )
    var fetchMineResult: Result<[MySuggestion], Error> = .success([])

    private(set) var currentLocationCalls = 0
    private(set) var submitted: [PlaceSuggestion] = []
    private(set) var searches: [Search] = []
    private(set) var submittedPlaces: [SubmittedPlace] = []
    private(set) var fetchMineCalls = 0

    func currentLocation() async throws -> SuggestedLocation {
        currentLocationCalls += 1
        return try currentLocationResult.get()
    }

    func submit(_ suggestion: PlaceSuggestion) async throws {
        try submitResult.get()
        submitted.append(suggestion)
    }

    func searchPlaces(query: String, near: SuggestedLocation?) async throws -> [SuggestedPlace] {
        searches.append(Search(query: query, near: near))
        return try searchResult.get()
    }

    func submit(_ place: SuggestedPlace, note: String) async throws -> MySuggestion {
        let suggestion = try submitPlaceResult.get()
        submittedPlaces.append(SubmittedPlace(place: place, note: note))
        return suggestion
    }

    func fetchMine() async throws -> [MySuggestion] {
        fetchMineCalls += 1
        return try fetchMineResult.get()
    }
}
