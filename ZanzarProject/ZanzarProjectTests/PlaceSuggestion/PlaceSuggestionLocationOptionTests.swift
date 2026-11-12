import Testing
@testable import ZanzarProject

@MainActor
@Suite("PlaceSuggestionViewModel location options")
struct PlaceSuggestionLocationOptionTests {
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

    @Test("Using the location puts the current address in the empty name field")
    func prefillsAddress() async {
        let viewModel = makeViewModel()
        await viewModel.loadCurrentLocation()

        viewModel.fillQueryWithCurrentAddress()

        #expect(viewModel.query == Self.home.address)
    }

    @Test("What the user typed is never overwritten")
    func keepsTypedText() async {
        let viewModel = makeViewModel()
        viewModel.query = "Jardim Botânico"
        await viewModel.loadCurrentLocation()

        viewModel.fillQueryWithCurrentAddress()

        #expect(viewModel.query == "Jardim Botânico")
    }

    @Test("Choosing another place takes the filled address out, and only that")
    func anotherPlaceClearsPrefill() async {
        let viewModel = makeViewModel()
        await viewModel.loadCurrentLocation()
        viewModel.fillQueryWithCurrentAddress()

        viewModel.useAnotherPlace()

        #expect(!viewModel.searchNearMe)
        #expect(viewModel.query.isEmpty)
    }

    @Test("Choosing another place keeps an address the user edited")
    func anotherPlaceKeepsEditedText() async {
        let viewModel = makeViewModel()
        await viewModel.loadCurrentLocation()
        viewModel.fillQueryWithCurrentAddress()
        viewModel.query = "Rua XV de Novembro, 1300"

        viewModel.useAnotherPlace()

        #expect(viewModel.query == "Rua XV de Novembro, 1300")
    }

    @Test("Going back to the location fills the address again")
    func backToLocation() async {
        let viewModel = makeViewModel()
        await viewModel.loadCurrentLocation()
        viewModel.fillQueryWithCurrentAddress()
        viewModel.useAnotherPlace()

        viewModel.useCurrentLocation()

        #expect(viewModel.searchNearMe)
        #expect(viewModel.query == Self.home.address)
    }

    @Test("Another place never fills the field")
    func noPrefillForAnotherPlace() async {
        let viewModel = makeViewModel()
        viewModel.useAnotherPlace()
        await viewModel.loadCurrentLocation()

        viewModel.fillQueryWithCurrentAddress()

        #expect(viewModel.query.isEmpty)
    }

    @Test("Coordinates are not offered as a name")
    func coordinatesAreNotAnAddress() async {
        let service = MockPlaceSuggestionService()
        service.currentLocationResult = .success(
            SuggestedLocation(
                latitude: -25.43,
                longitude: -49.27,
                address: SuggestedLocation.coordinateText(latitude: -25.43, longitude: -49.27)
            )
        )
        let viewModel = makeViewModel(service: service)
        await viewModel.loadCurrentLocation()

        viewModel.fillQueryWithCurrentAddress()

        #expect(viewModel.query.isEmpty)
    }
}
