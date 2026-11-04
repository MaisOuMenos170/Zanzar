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

    @Test("the button stays disabled until the reason is filled, even with a location")
    func cannotSubmitWithoutNote() async {
        let viewModel = makeViewModel()
        await viewModel.loadCurrentLocation()

        #expect(viewModel.currentLocation == Self.home)
        #expect(!viewModel.canSubmit)

        viewModel.note = "   "
        #expect(!viewModel.canSubmit)

        viewModel.note = "A comida é muito boa"
        #expect(viewModel.canSubmit)
    }

    @Test("with the current location chosen, the button needs the position to be found")
    func currentLocationModeNeedsPosition() {
        let viewModel = makeViewModel()
        viewModel.note = "Vale a pena"

        #expect(!viewModel.canSubmit)
    }

    @Test("with another place chosen, the button needs the typed name or address")
    func otherPlaceModeNeedsQuery() {
        let viewModel = makeViewModel()
        viewModel.mode = .otherPlace
        viewModel.note = "Vale a pena"
        #expect(!viewModel.canSubmit)

        viewModel.placeQuery = "  "
        #expect(!viewModel.canSubmit)

        viewModel.placeQuery = "Restaurante Spaghetto"
        #expect(viewModel.canSubmit)
    }

    @Test("a reason or address over the backend limit blocks the button")
    func limitsBlockSubmit() {
        let viewModel = makeViewModel()
        viewModel.mode = .otherPlace
        viewModel.placeQuery = "Restaurante Spaghetto"
        viewModel.note = String(repeating: "x", count: PlaceSuggestionLimits.noteMaxLength + 1)
        #expect(!viewModel.canSubmit)

        viewModel.note = String(repeating: "x", count: PlaceSuggestionLimits.noteMaxLength)
        #expect(viewModel.canSubmit)

        viewModel.placeQuery = String(repeating: "y", count: PlaceSuggestionLimits.addressMaxLength + 1)
        #expect(!viewModel.canSubmit)
    }

    @Test("the position is only looked up while the current-location option is selected")
    func loadsOnlyInCurrentLocationMode() async {
        let service = MockPlaceSuggestionService()
        let viewModel = makeViewModel(service: service)
        viewModel.mode = .otherPlace

        await viewModel.loadCurrentLocation()

        #expect(service.currentLocationCalls == 0)
        #expect(viewModel.currentLocation == nil)
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

    @Test("submitting from the current location sends that position and the trimmed reason")
    func submitCurrentLocation() async {
        let service = MockPlaceSuggestionService()
        let viewModel = makeViewModel(service: service)
        await viewModel.loadCurrentLocation()
        viewModel.note = "  Vale a pena \n"

        let succeeded = await viewModel.submit()

        #expect(succeeded)
        #expect(viewModel.outcome == .success)
        #expect(!viewModel.isSubmitting)
        #expect(service.submitted == [PlaceSuggestion(location: Self.home, note: "Vale a pena")])
    }

    @Test("submitting another place sends the typed address with zero coordinates and no lookup")
    func submitOtherPlaceSendsTypedAddress() async {
        let service = MockPlaceSuggestionService()
        let viewModel = makeViewModel(service: service)
        viewModel.mode = .otherPlace
        viewModel.placeQuery = "  Restaurante Spaghetto "
        viewModel.note = "A comida é muito boa"

        let succeeded = await viewModel.submit()

        #expect(succeeded)
        #expect(viewModel.outcome == .success)
        #expect(service.currentLocationCalls == 0)
        let expected = PlaceSuggestion(
            location: SuggestedLocation(latitude: 0, longitude: 0, address: "Restaurante Spaghetto"),
            note: "A comida é muito boa"
        )
        #expect(service.submitted == [expected])
    }

    @Test("a server failure keeps the form and shows an error")
    func submitServerFailure() async {
        let service = MockPlaceSuggestionService()
        service.submitResult = .failure(APIError.httpStatus(500, message: nil))
        let viewModel = makeViewModel(service: service)
        await viewModel.loadCurrentLocation()
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
        let viewModel = makeViewModel(service: service)
        await viewModel.loadCurrentLocation()
        viewModel.note = "Vale a pena"

        await viewModel.submit()

        #expect(viewModel.outcome == .failure(message: L10n.string("placeSuggestion.error.invalid")))
    }

    @Test("a cancelled request is not reported as an error")
    func submitCancellationIsSilent() async {
        let service = MockPlaceSuggestionService()
        service.submitResult = .failure(URLError(.cancelled))
        let viewModel = makeViewModel(service: service)
        await viewModel.loadCurrentLocation()
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
    }
}

final class MockPlaceSuggestionService: PlaceSuggestionServicing, @unchecked Sendable {
    var currentLocationResult: Result<SuggestedLocation, Error> = .success(
        SuggestedLocation(latitude: -25.43, longitude: -49.27, address: "Rua XV de Novembro, 1200")
    )
    var submitResult: Result<Void, Error> = .success(())

    private(set) var currentLocationCalls = 0
    private(set) var submitted: [PlaceSuggestion] = []

    func currentLocation() async throws -> SuggestedLocation {
        currentLocationCalls += 1
        return try currentLocationResult.get()
    }

    func submit(_ suggestion: PlaceSuggestion) async throws {
        try submitResult.get()
        submitted.append(suggestion)
    }
}
