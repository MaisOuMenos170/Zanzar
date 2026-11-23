import Testing
@testable import ZanzarProject

@MainActor
@Suite("PlaceSuggestionViewModel selection in the search field")
struct PlaceSuggestionViewModelSelectionTests {
    private static let garden = SuggestedPlace(
        name: "Jardim Botânico",
        address: "Rua Engenheiro Ostoja Roguski, 350, Jardim Botânico, Curitiba - PR, 80210-390, Brasil",
        latitude: -25.44,
        longitude: -49.24
    )

    private static let bareAddress = SuggestedPlace(
        name: nil,
        address: "Rua Engenheiro Ostoja Roguski, 360, Curitiba - PR, Brasil",
        latitude: -25.45,
        longitude: -49.25
    )

    private func makeViewModel(
        results: [SuggestedPlace],
        service: MockPlaceSuggestionService = MockPlaceSuggestionService()
    ) async -> PlaceSuggestionViewModel {
        service.searchResult = .success(results)
        let viewModel = PlaceSuggestionViewModel(service: service, debounce: .zero)
        viewModel.query = "jardim"
        await viewModel.waitForSearch()
        return viewModel
    }

    @Test("the text of a place is its name and its address without the postal code")
    func searchFieldText() {
        #expect(
            Self.garden.searchFieldText
                == "Jardim Botânico, Rua Engenheiro Ostoja Roguski, 350, Jardim Botânico, Curitiba - PR, Brasil"
        )
        #expect(Self.bareAddress.searchFieldText == "Rua Engenheiro Ostoja Roguski, 360, Curitiba - PR, Brasil")
        let nameOnly = SuggestedPlace(name: "Padaria", address: nil, latitude: 0, longitude: 0)
        #expect(nameOnly.searchFieldText == "Padaria")
    }

    @Test("choosing a place writes it in the search field")
    func selectWritesQuery() async {
        let viewModel = await makeViewModel(results: [Self.garden])

        viewModel.select(Self.garden)

        #expect(viewModel.query == Self.garden.searchFieldText)
        #expect(viewModel.selectedPlace == Self.garden)
    }

    @Test("writing the place in the field does not start a search that drops it")
    func selectDoesNotSearchAgain() async {
        let service = MockPlaceSuggestionService()
        let viewModel = await makeViewModel(results: [Self.garden], service: service)

        viewModel.select(Self.garden)
        await viewModel.waitForSearch()

        #expect(service.searches.count == 1)
        #expect(viewModel.selectedPlace == Self.garden)
        #expect(viewModel.results == [Self.garden])
    }

    @Test("a search still waiting when a place is chosen is cancelled")
    func selectCancelsPendingSearch() async {
        let service = MockPlaceSuggestionService()
        service.searchResult = .success([Self.garden])
        let viewModel = PlaceSuggestionViewModel(service: service, debounce: .milliseconds(80))
        viewModel.query = "jardim"
        viewModel.submitSearch()
        await viewModel.waitForSearch()
        // Another keystroke starts the wait for a new search; the user taps a result of the previous one.
        viewModel.query = "jardim b"

        viewModel.select(Self.garden)
        await viewModel.waitForSearch()
        try? await Task.sleep(for: .milliseconds(150))

        #expect(service.searches.count == 1)
        #expect(viewModel.selectedPlace == Self.garden)
        #expect(!viewModel.isSearching)
    }

    @Test("typing again after choosing starts a new search and drops the choice")
    func typingAfterSelectSearchesAgain() async {
        let service = MockPlaceSuggestionService()
        let viewModel = await makeViewModel(results: [Self.garden], service: service)
        viewModel.select(Self.garden)

        viewModel.query += " x"
        await viewModel.waitForSearch()

        #expect(service.searches.count == 2)
        #expect(viewModel.selectedPlace == nil)
    }

    @Test("a place with no name asks for the name even though it is written in the field")
    func bareAddressStillAsksForName() async {
        let viewModel = await makeViewModel(results: [Self.bareAddress])

        viewModel.select(Self.bareAddress)

        #expect(viewModel.query == Self.bareAddress.searchFieldText)
        #expect(viewModel.needsName)
        #expect(!viewModel.canSubmit)
    }

    @Test("filling it in by hand after choosing puts back what was typed, and does not search again")
    func manualEntryRestoresTypedText() async {
        let service = MockPlaceSuggestionService()
        let viewModel = await makeViewModel(results: [Self.garden], service: service)
        viewModel.select(Self.garden)

        viewModel.enterManually()
        await viewModel.waitForSearch()

        #expect(viewModel.query == "jardim")
        #expect(viewModel.customName == "jardim")
        #expect(viewModel.isManualEntry)
        #expect(service.searches.count == 1)
    }
}
