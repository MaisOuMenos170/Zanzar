import Foundation
import Testing
@testable import ZanzarProject

@MainActor
@Suite("SavedPlacesViewModel")
struct SavedPlacesViewModelTests {
    private static func place(_ id: String, _ name: String?) -> SavedPlace {
        SavedPlace(placeID: id, name: name, imageURL: nil, savedAt: .now)
    }

    private static let arcadia = place("arcadia", "Arcádia - Sebo e Café")
    private static let barigui = place("barigui", "Parque Barigui")
    private static let jardim = place("jardim", "Jardim Botânico")

    private func makeModel(
        saved: FakeSavedPlacesService,
        userID: String? = "user-1"
    ) -> SavedPlacesViewModel {
        SavedPlacesViewModel(service: saved, userIDProvider: { userID })
    }

    private func loadedModel() async -> (SavedPlacesViewModel, FakeSavedPlacesService) {
        let saved = FakeSavedPlacesService(savedIDs: ["arcadia", "barigui", "jardim"])
        saved.listed = [Self.arcadia, Self.barigui, Self.jardim]
        let model = makeModel(saved: saved)
        await model.load()
        return (model, saved)
    }

    @Test("loads the saved places")
    func loads() async {
        let (model, _) = await loadedModel()

        #expect(model.hasLoaded)
        #expect(model.places.count == 3)
    }

    @Test("a failed load says so and leaves the list empty")
    func failedLoad() async {
        let model = makeModel(saved: FakeSavedPlacesService(failure: APIError.invalidResponse))
        await model.load()

        #expect(model.errorMessage != nil)
        #expect(model.places.isEmpty)
        #expect(model.hasLoaded)
    }

    @Test("without a signed-in user nothing is loaded")
    func needsUser() async {
        let model = makeModel(saved: FakeSavedPlacesService(), userID: nil)
        await model.load()

        #expect(!model.hasLoaded)
    }

    @Test("search matches the name ignoring case and accents")
    func searches() async {
        let (model, _) = await loadedModel()

        model.searchText = " botanico "
        #expect(model.visiblePlaces { _ in nil } == [Self.jardim])

        model.searchText = "Casa do Sapo"
        #expect(model.visiblePlaces { _ in nil }.isEmpty)
    }

    @Test("a category chip keeps the places the map knows to be of it, and Todos keeps all")
    func filtersByCategory() async {
        let (model, _) = await loadedModel()
        let categories: [String: ZanzarPlaceCategory] = ["barigui": .park, "jardim": .park, "arcadia": .cafe]

        model.filter = .parks
        #expect(model.visiblePlaces { categories[$0.placeID] } == [Self.barigui, Self.jardim])

        model.filter = .all
        #expect(model.visiblePlaces { categories[$0.placeID] }.count == 3)

        // A place whose category the app does not know only shows under Todos.
        model.filter = .parks
        #expect(model.visiblePlaces { _ in nil }.isEmpty)
    }

    @Test("removing takes the place off the list and asks the backend")
    func removes() async {
        let (model, saved) = await loadedModel()

        let outcome = await model.remove(Self.barigui)

        #expect(outcome == .removed)
        #expect(model.places == [Self.arcadia, Self.jardim])
        #expect(saved.removeCalls == ["barigui"])
    }

    @Test("a refused removal puts the place back where it was")
    func failedRemoval() async {
        let (model, saved) = await loadedModel()
        saved.removeFailure = APIError.httpStatus(500, message: nil)

        let outcome = await model.remove(Self.barigui)

        #expect(outcome == .failed(message: L10n.string("placeDetail.saveButton.failedToast")))
        #expect(model.places == [Self.arcadia, Self.barigui, Self.jardim])
    }
}
