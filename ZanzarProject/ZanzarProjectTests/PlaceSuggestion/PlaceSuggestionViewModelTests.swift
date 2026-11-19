import Foundation
import Testing
@testable import ZanzarProject

@MainActor
@Suite("PlaceSuggestionViewModel")
struct PlaceSuggestionViewModelTests {
    static let home = SuggestedLocation(
        latitude: -25.43,
        longitude: -49.27,
        address: "Rua XV de Novembro, 1200"
    )

    /// Apple Maps knows both its name and its address.
    static let garden = SuggestedPlace(
        name: "Jardim Botânico",
        address: "Rua Engenheiro Ostoja Roguski, 350, Curitiba",
        latitude: -25.44,
        longitude: -49.24
    )

    /// An address with nothing attached to it.
    static let bareAddress = SuggestedPlace(
        name: nil,
        address: "Rua Engenheiro Ostoja Roguski, 360, Curitiba",
        latitude: -25.45,
        longitude: -49.25
    )

    /// A place Apple Maps names but has no address for.
    static let bakery = SuggestedPlace(
        name: "Padaria Central",
        address: nil,
        latitude: -25.41,
        longitude: -49.26
    )

    func makeViewModel(
        service: MockPlaceSuggestionService = MockPlaceSuggestionService()
    ) -> PlaceSuggestionViewModel {
        PlaceSuggestionViewModel(service: service, debounce: .zero)
    }

    func makeViewModel(
        searching results: [SuggestedPlace],
        service: MockPlaceSuggestionService
    ) async -> PlaceSuggestionViewModel {
        service.searchResult = .success(results)
        let viewModel = makeViewModel(service: service)
        viewModel.query = "jardim"
        await viewModel.waitForSearch()
        return viewModel
    }

    // MARK: Search

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

        await viewModel.waitForSearch()

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
        await viewModel.waitForSearch()

        #expect(service.currentLocationCalls == 0)
        #expect(service.searches == [.init(query: "jardim", near: nil)])
    }

    @Test("a new search clears the chosen place and what was typed for it")
    func searchResetsSelection() async {
        let service = MockPlaceSuggestionService()
        let viewModel = await makeViewModel(searching: [Self.bareAddress], service: service)
        viewModel.select(Self.bareAddress)
        viewModel.customName = "Cantinho"

        viewModel.query = "jardim botânico"
        await viewModel.waitForSearch()

        #expect(viewModel.selectedPlace == nil)
        #expect(viewModel.customName.isEmpty)
        #expect(viewModel.customAddress.isEmpty)
    }

    @Test("typing searches once, after the pause, with the last text")
    func debouncesTyping() async {
        let service = MockPlaceSuggestionService()
        let viewModel = PlaceSuggestionViewModel(service: service, debounce: .milliseconds(100))

        viewModel.query = "ja"
        viewModel.query = "jar"
        viewModel.query = "jard"
        #expect(service.searches.isEmpty)
        await viewModel.waitForSearch()

        #expect(service.searches == [.init(query: "jard", near: nil)])
    }

    @Test("the keyboard's search key skips the pause")
    func submitSearchSkipsPause() async {
        let service = MockPlaceSuggestionService()
        let viewModel = PlaceSuggestionViewModel(service: service, debounce: .seconds(60))
        viewModel.query = "jardim"

        viewModel.submitSearch()
        await viewModel.waitForSearch()

        #expect(service.searches == [.init(query: "jardim", near: nil)])
        #expect(viewModel.hasSearched)
    }

    @Test("erasing the text clears the results and what was asked for")
    func shortTextClearsResults() async {
        let service = MockPlaceSuggestionService()
        let viewModel = await makeViewModel(searching: [Self.bareAddress], service: service)
        viewModel.select(Self.bareAddress)
        viewModel.customName = "Cantinho"

        viewModel.query = "j"

        #expect(viewModel.results.isEmpty)
        #expect(!viewModel.hasSearched)
        #expect(viewModel.selection == .none)
        #expect(viewModel.customName.isEmpty)
        #expect(!viewModel.isSearching)
    }

    @Test("a text that is too short is never searched")
    func shortTextIsNotSearched() async {
        let service = MockPlaceSuggestionService()
        let viewModel = makeViewModel(service: service)

        viewModel.query = "j"
        await viewModel.waitForSearch()

        #expect(service.searches.isEmpty)
    }

    @Test("a failed search shows its message and keeps the form")
    func searchFailure() async {
        let service = MockPlaceSuggestionService()
        service.searchResult = .failure(URLError(.notConnectedToInternet))
        let viewModel = makeViewModel(service: service)
        viewModel.query = "jardim"

        await viewModel.waitForSearch()

        #expect(viewModel.searchErrorMessage == L10n.string("placeSuggestion.error.search"))
        #expect(viewModel.results.isEmpty)
        #expect(!viewModel.hasSearched)
        #expect(!viewModel.isSearching)
        #expect(viewModel.selection == .none)
    }

    // MARK: Which fields the place needs

    @Test("a place with a name and an address asks for nothing else")
    func completePlaceNeedsNothing() async {
        let viewModel = await makeViewModel(searching: [Self.garden], service: MockPlaceSuggestionService())

        viewModel.select(Self.garden)

        #expect(!viewModel.needsName)
        #expect(!viewModel.needsAddress)
        #expect(viewModel.canSubmit)
    }

    @Test("an address with no name asks for the name")
    func addressWithoutNameAsksForName() async {
        let viewModel = await makeViewModel(searching: [Self.bareAddress], service: MockPlaceSuggestionService())

        viewModel.select(Self.bareAddress)

        #expect(viewModel.needsName)
        #expect(!viewModel.needsAddress)
        #expect(!viewModel.canSubmit)

        viewModel.customName = "   "
        #expect(!viewModel.canSubmit)

        viewModel.customName = "Cantinho do Café"
        #expect(viewModel.canSubmit)
    }

    @Test("a named place with no address asks for the address")
    func nameWithoutAddressAsksForAddress() async {
        let viewModel = await makeViewModel(searching: [Self.bakery], service: MockPlaceSuggestionService())

        viewModel.select(Self.bakery)

        #expect(!viewModel.needsName)
        #expect(viewModel.needsAddress)
        #expect(!viewModel.canSubmit)

        viewModel.customAddress = "Rua A, 10"
        #expect(viewModel.canSubmit)
    }

    @Test("nothing chosen asks for nothing and cannot be sent")
    func nothingChosen() async {
        let viewModel = await makeViewModel(searching: [Self.garden], service: MockPlaceSuggestionService())

        #expect(!viewModel.needsName)
        #expect(!viewModel.needsAddress)
        #expect(!viewModel.canSubmit)
    }

    @Test("a search with no results opens the manual form with the searched text as the name")
    func emptyResultsOpenManualForm() async {
        let viewModel = await makeViewModel(searching: [], service: MockPlaceSuggestionService())

        #expect(viewModel.hasSearched)
        #expect(viewModel.isManualEntry)
        #expect(viewModel.needsName)
        #expect(viewModel.needsAddress)
        #expect(viewModel.customName == "jardim")
        #expect(!viewModel.canSubmit)

        viewModel.customAddress = "Rua A, 10"
        #expect(viewModel.canSubmit)
    }

    @Test("choosing to fill it in by hand keeps a name already typed")
    func manualEntryKeepsTypedName() async {
        let viewModel = await makeViewModel(searching: [Self.garden], service: MockPlaceSuggestionService())
        viewModel.select(Self.garden)

        viewModel.enterManually()
        #expect(viewModel.selectedPlace == nil)
        #expect(viewModel.isManualEntry)
        #expect(viewModel.customName == "jardim")

        viewModel.customName = "Meu lugar"
        viewModel.enterManually()
        #expect(viewModel.customName == "Meu lugar")
    }

    @Test("a name or address over the limit blocks the button")
    func fieldLimits() async {
        let viewModel = await makeViewModel(searching: [], service: MockPlaceSuggestionService())
        viewModel.customAddress = "Rua A, 10"
        #expect(viewModel.canSubmit)

        viewModel.customName = String(repeating: "x", count: PlaceSuggestionLimits.nameMaxLength + 1)
        #expect(!viewModel.canSubmit)

        viewModel.customName = "Lugar"
        viewModel.customAddress = String(repeating: "y", count: PlaceSuggestionLimits.addressMaxLength + 1)
        #expect(!viewModel.canSubmit)
    }

    @Test("the note is optional but has a limit")
    func noteIsOptionalWithLimit() async {
        let viewModel = await makeViewModel(searching: [Self.garden], service: MockPlaceSuggestionService())
        viewModel.select(Self.garden)
        #expect(viewModel.note.isEmpty)
        #expect(viewModel.canSubmit)

        viewModel.note = String(repeating: "x", count: PlaceSuggestionLimits.noteMaxLength + 1)
        #expect(!viewModel.canSubmit)

        viewModel.note = String(repeating: "x", count: PlaceSuggestionLimits.noteMaxLength)
        #expect(viewModel.canSubmit)
    }

    // MARK: Position of the user

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
