import Foundation
import Testing
@testable import ZanzarProject

@MainActor
@Suite("PlaceDetail bookmark")
struct PlaceDetailSavedPlaceTests {
    private func makeViewModel(saved: FakeSavedPlacesService, userID: String? = "user-1") -> PlaceDetailViewModel {
        PlaceDetailViewModel(
            place: MapPlace(
                id: "place-1", name: "Parque", latitude: 0, longitude: 0, category: .park, distanceMeters: nil
            ),
            userIDProvider: { userID },
            userCoordinateProvider: { throw CancellationError() },
            savedPlaces: saved
        )
    }

    @Test("starts saved when the place is on the user's list")
    func loadsSavedState() async {
        let viewModel = makeViewModel(saved: FakeSavedPlacesService(savedIDs: ["place-1", "other"]))

        await viewModel.loadSavedState()

        #expect(viewModel.isSaved)
    }

    @Test("starts unsaved when the place is not on the list")
    func loadsUnsavedState() async {
        let viewModel = makeViewModel(saved: FakeSavedPlacesService(savedIDs: ["other"]))

        await viewModel.loadSavedState()

        #expect(!viewModel.isSaved)
    }

    @Test("toggling saves, then removes")
    func togglesSavedPlace() async {
        let saved = FakeSavedPlacesService()
        let viewModel = makeViewModel(saved: saved)

        await viewModel.toggleSaved()
        #expect(viewModel.isSaved)
        #expect(saved.saveCalls == ["place-1"])

        await viewModel.toggleSaved()
        #expect(!viewModel.isSaved)
        #expect(saved.removeCalls == ["place-1"])
    }

    @Test("puts the bookmark back and tells the user when saving fails")
    func revertsOnFailure() async {
        let viewModel = makeViewModel(saved: FakeSavedPlacesService(failure: APIError.httpStatus(500, message: "boom")))

        await viewModel.toggleSaved()

        #expect(!viewModel.isSaved)
        #expect(viewModel.errorMessage != nil)
    }

    @Test("the limit of saved places gets its own message")
    func limitReached() async {
        let viewModel = makeViewModel(saved: FakeSavedPlacesService(failure: APIError.httpStatus(409, message: nil)))

        await viewModel.toggleSaved()

        #expect(!viewModel.isSaved)
        #expect(viewModel.errorMessage == L10n.string("placeDetail.saveButton.limitReached"))
    }

    @Test("does nothing without a signed-in user")
    func needsUser() async {
        let saved = FakeSavedPlacesService()
        let viewModel = makeViewModel(saved: saved, userID: nil)

        await viewModel.toggleSaved()

        #expect(!viewModel.isSaved)
        #expect(saved.saveCalls.isEmpty)
    }
}
