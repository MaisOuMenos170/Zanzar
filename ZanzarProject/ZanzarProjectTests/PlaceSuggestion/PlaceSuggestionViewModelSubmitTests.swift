import Foundation
import Testing
@testable import ZanzarProject

@MainActor
@Suite("PlaceSuggestionViewModel submit")
struct PlaceSuggestionViewModelSubmitTests {
    private typealias Fixtures = PlaceSuggestionViewModelTests

    private static let garden = Fixtures.garden
    private static let bareAddress = Fixtures.bareAddress
    private static let bakery = Fixtures.bakery
    private static let home = Fixtures.home

    private func makeViewModel(service: MockPlaceSuggestionService) -> PlaceSuggestionViewModel {
        PlaceSuggestionViewModel(service: service, debounce: .zero)
    }

    private func makeViewModel(
        searching results: [SuggestedPlace],
        service: MockPlaceSuggestionService
    ) async -> PlaceSuggestionViewModel {
        service.searchResult = .success(results)
        let viewModel = PlaceSuggestionViewModel(service: service, debounce: .zero)
        viewModel.query = "jardim"
        await viewModel.waitForSearch()
        return viewModel
    }

    @Test("a place with a name and an address goes with its own position and no lookup")
    func submitCompletePlace() async {
        let service = MockPlaceSuggestionService()
        let viewModel = await makeViewModel(searching: [Self.garden], service: service)
        viewModel.select(Self.garden)
        viewModel.note = "  O jardim de inverno é lindo \n"

        let succeeded = await viewModel.submit()

        #expect(succeeded)
        #expect(viewModel.outcome == .success)
        #expect(!viewModel.isSubmitting)
        #expect(service.resolvedAddresses.isEmpty)
        let expected = PlaceSuggestion(
            name: "Jardim Botânico",
            location: SuggestedLocation(
                latitude: -25.44,
                longitude: -49.24,
                address: "Rua Engenheiro Ostoja Roguski, 350, Curitiba"
            ),
            note: "O jardim de inverno é lindo"
        )
        #expect(service.submitted == [expected])
    }

    @Test("the verdict of the backend becomes the outcome")
    func submitShowsTheVerdict() async {
        let service = MockPlaceSuggestionService()
        service.submitResult = .success(.published(placeName: "Jardim Botânico"))
        let viewModel = await makeViewModel(searching: [Self.garden], service: service)
        viewModel.select(Self.garden)

        await viewModel.submit()

        #expect(viewModel.outcome == .published(placeName: "Jardim Botânico"))
    }

    @Test("the description can be left empty")
    func submitWithoutNote() async {
        let service = MockPlaceSuggestionService()
        let viewModel = await makeViewModel(searching: [Self.garden], service: service)
        viewModel.select(Self.garden)

        let succeeded = await viewModel.submit()

        #expect(succeeded)
        #expect(service.submitted.first?.note == "")
    }

    @Test("an address with no name goes with the name the user typed and the address position")
    func submitAddressWithTypedName() async {
        let service = MockPlaceSuggestionService()
        let viewModel = await makeViewModel(searching: [Self.bareAddress], service: service)
        viewModel.select(Self.bareAddress)
        viewModel.customName = "  Cantinho do Café "

        await viewModel.submit()

        let expected = PlaceSuggestion(
            name: "Cantinho do Café",
            location: SuggestedLocation(
                latitude: -25.45,
                longitude: -49.25,
                address: "Rua Engenheiro Ostoja Roguski, 360, Curitiba"
            ),
            note: ""
        )
        #expect(service.submitted == [expected])
        #expect(service.resolvedAddresses.isEmpty)
    }

    @Test("a typed address is looked up and its position and written form are sent")
    func submitTypedAddressResolved() async {
        let service = MockPlaceSuggestionService()
        service.resolveResult = .success(
            SuggestedPlace(name: nil, address: "Rua A, 10, Centro, Curitiba", latitude: -25.5, longitude: -49.3)
        )
        let viewModel = await makeViewModel(searching: [Self.bakery], service: service)
        viewModel.select(Self.bakery)
        viewModel.customAddress = " R. A 10 "

        let succeeded = await viewModel.submit()

        #expect(succeeded)
        #expect(service.resolvedAddresses == [.init(query: "R. A 10", near: nil)])
        let expected = PlaceSuggestion(
            name: "Padaria Central",
            location: SuggestedLocation(latitude: -25.5, longitude: -49.3, address: "Rua A, 10, Centro, Curitiba"),
            note: ""
        )
        #expect(service.submitted == [expected])
    }

    @Test("a typed address is looked up near the user when they allowed it")
    func resolveNearUser() async {
        let service = MockPlaceSuggestionService()
        service.resolveResult = .success(
            SuggestedPlace(name: nil, address: "Rua A, 10", latitude: -25.5, longitude: -49.3)
        )
        let viewModel = makeViewModel(service: service)
        await viewModel.loadCurrentLocation()
        viewModel.query = "lugar"
        service.searchResult = .success([])
        await viewModel.waitForSearch()
        viewModel.customAddress = "Rua A, 10"

        await viewModel.submit()

        #expect(service.resolvedAddresses == [.init(query: "Rua A, 10", near: Self.home)])
    }

    @Test("a named place keeps its own position when its typed address is not on the map")
    func submitNamedPlaceKeepsPositionWhenAddressNotFound() async {
        let service = MockPlaceSuggestionService()
        service.resolveResult = .success(nil)
        let viewModel = await makeViewModel(searching: [Self.bakery], service: service)
        viewModel.select(Self.bakery)
        viewModel.customAddress = "Rua A, 10"

        let succeeded = await viewModel.submit()

        #expect(succeeded)
        let expected = PlaceSuggestion(
            name: "Padaria Central",
            location: SuggestedLocation(latitude: -25.41, longitude: -49.26, address: "Rua A, 10"),
            note: ""
        )
        #expect(service.submitted == [expected])
    }

    @Test("a place filled in by hand is sent with the position of its address")
    func submitManualPlace() async {
        let service = MockPlaceSuggestionService()
        service.resolveResult = .success(
            SuggestedPlace(name: nil, address: "Rua A, 10, Curitiba", latitude: -25.5, longitude: -49.3)
        )
        let viewModel = await makeViewModel(searching: [], service: service)
        viewModel.customName = "  Restaurante Spaghetto "
        viewModel.customAddress = "Rua A, 10"
        viewModel.note = "A comida é muito boa"

        let succeeded = await viewModel.submit()

        #expect(succeeded)
        let expected = PlaceSuggestion(
            name: "Restaurante Spaghetto",
            location: SuggestedLocation(latitude: -25.5, longitude: -49.3, address: "Rua A, 10, Curitiba"),
            note: "A comida é muito boa"
        )
        #expect(service.submitted == [expected])
    }

    @Test("an address that cannot be placed stops the suggestion and says so on the address field")
    func submitManualPlaceAddressNotFound() async {
        let service = MockPlaceSuggestionService()
        service.resolveResult = .success(nil)
        let viewModel = await makeViewModel(searching: [], service: service)
        viewModel.customAddress = "Rua que não existe, 99999"

        let succeeded = await viewModel.submit()

        #expect(!succeeded)
        #expect(service.submitted.isEmpty)
        #expect(viewModel.outcome == nil)
        #expect(viewModel.addressErrorMessage == L10n.string("placeSuggestion.error.addressNotFound"))
        #expect(!viewModel.isSubmitting)

        viewModel.customAddress = "Rua XV de Novembro, 1200"
        #expect(viewModel.addressErrorMessage == nil)
    }

    @Test("a lookup that fails is told as a failure, not as a wrong address")
    func submitLookupFailure() async {
        let service = MockPlaceSuggestionService()
        service.resolveResult = .failure(URLError(.notConnectedToInternet))
        let viewModel = await makeViewModel(searching: [], service: service)
        viewModel.customAddress = "Rua A, 10"

        let succeeded = await viewModel.submit()

        #expect(!succeeded)
        #expect(viewModel.addressErrorMessage == nil)
        #expect(viewModel.outcome == .failure(message: L10n.string("placeSuggestion.error.generic")))
    }

    @Test("a server failure keeps the form and shows an error")
    func submitServerFailure() async {
        let service = MockPlaceSuggestionService()
        service.submitResult = .failure(APIError.httpStatus(500, message: nil))
        let viewModel = await makeViewModel(searching: [Self.garden], service: service)
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
        service.submitResult = .failure(APIError.httpStatus(400, message: "invalid"))
        let viewModel = await makeViewModel(searching: [Self.garden], service: service)
        viewModel.select(Self.garden)

        await viewModel.submit()

        #expect(viewModel.outcome == .failure(message: L10n.string("placeSuggestion.error.invalid")))
    }

    @Test("a cancelled request is not reported as an error")
    func submitCancellationIsSilent() async {
        let service = MockPlaceSuggestionService()
        service.submitResult = .failure(URLError(.cancelled))
        let viewModel = await makeViewModel(searching: [Self.garden], service: service)
        viewModel.select(Self.garden)

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
    }
}
