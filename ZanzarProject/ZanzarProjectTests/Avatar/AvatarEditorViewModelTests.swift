import Foundation
import SwiftUI
import Testing
@testable import ZanzarProject

@MainActor
@Suite("AvatarEditorViewModel")
struct AvatarEditorViewModelTests {
    private static let stored = Avatar(skin: 3, eyes: 2, eyebrow: 5, eyelash: 4, hair: 7, background: "#112233")

    private func makeViewModel(
        service: MockAvatarService = MockAvatarService(),
        userID: String? = "user-1"
    ) -> AvatarEditorViewModel {
        AvatarEditorViewModel(service: service, userIDProvider: { userID })
    }

    @Test("starts on the default face with the skin tab")
    func startsWithDefaults() {
        let viewModel = makeViewModel()

        #expect(viewModel.avatar == .placeholder)
        #expect(viewModel.selectedTab == .skin)
        #expect(viewModel.avatar.hair == Avatar.none)
        #expect(viewModel.avatar.eyelash == Avatar.none)
    }

    @Test("select changes the layer of the current tab only")
    func selectChangesCurrentTab() {
        let viewModel = makeViewModel()

        viewModel.selectedTab = .eyes
        viewModel.select(4)
        viewModel.selectedTab = .hair
        viewModel.select(6)

        #expect(viewModel.avatar.eyes == 4)
        #expect(viewModel.avatar.hair == 6)
        #expect(viewModel.avatar.skin == Avatar.placeholder.skin)
        #expect(viewModel.value(for: .eyes) == 4)
        #expect(viewModel.selectedValue == 6)
    }

    @Test("hair and eyelash can be turned off, the other layers cannot")
    func noneOnlyForOptionalLayers() {
        let viewModel = AvatarEditorViewModel(
            service: MockAvatarService(),
            userIDProvider: { "user-1" },
            avatar: Self.stored
        )

        viewModel.selectedTab = .hair
        viewModel.select(Avatar.none)
        viewModel.selectedTab = .eyelash
        viewModel.select(Avatar.none)
        viewModel.selectedTab = .skin
        viewModel.select(Avatar.none)

        #expect(viewModel.avatar.hair == Avatar.none)
        #expect(viewModel.avatar.eyelash == Avatar.none)
        #expect(viewModel.avatar.skin == Self.stored.skin)
    }

    @Test("ids outside a layer's range are ignored", arguments: [
        (AvatarEditorTab.skin, 9), (.eyes, 7), (.eyebrow, 6), (.eyelash, 6), (.hair, 8), (.hair, -1)
    ])
    func ignoresOutOfRange(tab: AvatarEditorTab, value: Int) {
        let viewModel = makeViewModel()
        viewModel.selectedTab = tab
        let before = viewModel.avatar

        viewModel.select(value)

        #expect(viewModel.avatar == before)
    }

    @Test("the background color round-trips through the hex string")
    func backgroundColor() {
        let viewModel = makeViewModel()

        viewModel.backgroundColor = Color(hex: "#00FF7F") ?? .clear

        #expect(viewModel.avatar.background == "#00FF7F")
    }

    @Test("load starts from the avatar the user already has")
    func loadUsesStoredAvatar() async {
        let service = MockAvatarService(fetchResult: .success(Self.stored))
        let viewModel = makeViewModel(service: service)

        await viewModel.load()

        #expect(viewModel.avatar == Self.stored)
        #expect(!viewModel.isLoading)
    }

    @Test("a failed load keeps the default face")
    func loadFailureKeepsDefault() async {
        let service = MockAvatarService(fetchResult: .failure(APIError.httpStatus(500, message: nil)))
        let viewModel = makeViewModel(service: service)

        await viewModel.load()

        #expect(viewModel.avatar == .placeholder)
    }

    @Test("save creates the avatar of a new user")
    func saveCreates() async {
        let service = MockAvatarService(fetchResult: .success(nil))
        let viewModel = makeViewModel(service: service)
        await viewModel.load()
        viewModel.selectedTab = .hair
        viewModel.select(2)
        service.createResult = .success(viewModel.avatar)

        let saved = await viewModel.save()

        #expect(saved)
        #expect(service.lastCreated?.hair == 2)
        #expect(service.lastUpdated == nil)
        #expect(viewModel.saveError == nil)
        #expect(!viewModel.isSaving)
    }

    @Test("save updates an avatar that already exists")
    func saveUpdates() async {
        let service = MockAvatarService(fetchResult: .success(Self.stored))
        service.updateResult = .success(Self.stored)
        let viewModel = makeViewModel(service: service)
        await viewModel.load()

        let saved = await viewModel.save()

        #expect(saved)
        #expect(service.lastUpdated == Self.stored)
        #expect(service.lastCreated == nil)
    }

    @Test("a 409 on create falls back to updating the avatar")
    func saveConflictUpdates() async {
        let service = MockAvatarService(
            fetchResult: .success(nil),
            createResult: .failure(APIError.httpStatus(409, message: nil))
        )
        service.updateResult = .success(.placeholder)
        let viewModel = makeViewModel(service: service)

        let saved = await viewModel.save()

        #expect(saved)
        #expect(service.lastUpdated == .placeholder)
    }

    @Test("a failed save reports a generic error and can be retried")
    func saveFailure() async {
        let service = MockAvatarService(
            fetchResult: .success(nil),
            createResult: .failure(APIError.httpStatus(500, message: "boom"))
        )
        let viewModel = makeViewModel(service: service)

        let saved = await viewModel.save()

        #expect(!saved)
        #expect(viewModel.saveError == L10n.string("avatarEditor.saveError.message"))
        #expect(!viewModel.isSaving)
    }

    @Test("save without a signed-in user sends nothing")
    func saveWithoutUser() async {
        let service = MockAvatarService()
        let viewModel = makeViewModel(service: service, userID: nil)

        let saved = await viewModel.save()

        #expect(!saved)
        #expect(service.lastCreated == nil)
        #expect(service.lastUpdated == nil)
        #expect(viewModel.saveError == L10n.string("avatar.loadError.notAuthenticated"))
    }
}

@Suite("AvatarCatalog")
struct AvatarCatalogTests {
    @Test("every tab offers as many options as the asset catalog and backend know")
    func optionCounts() {
        #expect(AvatarEditorTab.skin.optionCount == 8)
        #expect(AvatarEditorTab.eyes.optionCount == 6)
        #expect(AvatarEditorTab.eyebrow.optionCount == 5)
        #expect(AvatarEditorTab.eyelash.optionCount == 5)
        #expect(AvatarEditorTab.hair.optionCount == 7)
    }

    @Test("swatch colors are valid hex colors", arguments: [
        AvatarCatalog.eyeColors, AvatarCatalog.eyebrowColors, AvatarCatalog.eyelashColors
    ])
    func swatchesAreValid(colors: [String]) {
        #expect(colors.allSatisfy { Color(hex: $0) != nil })
    }

    @Test("every hair is placed on the face, none is not", arguments: 1...7)
    func everyHairHasAPlacement(hair: Int) {
        #expect(AvatarHairLayout.placement(for: hair) != nil)
    }

    @Test("the none option and unknown ids have no placement")
    func noPlacementForNone() {
        #expect(AvatarHairLayout.placement(for: Avatar.none) == nil)
        #expect(AvatarHairLayout.placement(for: 8) == nil)
    }
}
