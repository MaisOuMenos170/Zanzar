import Testing
@testable import ZanzarProject

@MainActor
@Suite("Profile account and filters")
struct ProfileAccountTests {
    fileprivate static let profile = Profile(
        summary: ProfileSummary(name: "Bia", checkInCount: 2, itineraryCount: 1, sealCount: 3),
        recentCheckIns: []
    )

    @Test("saving a new name sends it trimmed")
    func saveNameSendsTrimmedName() async {
        let service = AccountServiceSpy()
        let viewModel = EditNameViewModel(currentName: "Bia", service: service, userIDProvider: { "user-1" })
        #expect(viewModel.name.isEmpty)

        viewModel.name = "  Aline "
        #expect(viewModel.canSave)
        let saved = await viewModel.save()

        #expect(saved)
        #expect(service.renamed == ["Aline"])
        #expect(viewModel.didSave)
        #expect(viewModel.errorMessage == nil)
    }

    @Test("the button stays off for an empty, too short, too long or unchanged name")
    func canSaveNeedsAValidNewName() {
        let viewModel = EditNameViewModel(currentName: "Bia", service: AccountServiceSpy(), userIDProvider: { "user-1" })

        #expect(!viewModel.canSave)
        viewModel.name = "   "
        #expect(!viewModel.canSave)
        viewModel.name = "Al"
        #expect(!viewModel.canSave)
        viewModel.name = String(repeating: "a", count: 31)
        #expect(!viewModel.canSave)
        viewModel.name = "Aline"
        #expect(viewModel.canSave)
    }

    @Test("the current name, even with spaces around it, is not sent again")
    func saveIgnoresTheCurrentName() async {
        let service = AccountServiceSpy()
        let viewModel = EditNameViewModel(currentName: "Bia", service: service, userIDProvider: { "user-1" })

        viewModel.name = "  Bia "
        #expect(!viewModel.canSave)
        let saved = await viewModel.save()

        #expect(!saved)
        #expect(service.renamed.isEmpty)
    }

    @Test("an invalid name is not sent")
    func saveIgnoresInvalidName() async {
        let service = AccountServiceSpy()
        let viewModel = EditNameViewModel(currentName: "Bia", service: service, userIDProvider: { "user-1" })

        viewModel.name = "  "
        let saved = await viewModel.save()

        #expect(!saved)
        #expect(service.renamed.isEmpty)
    }

    @Test("a failed rename flags the error and does not count as saved")
    func saveNameFailure() async {
        let service = AccountServiceSpy()
        service.failsAccountCalls = true
        let viewModel = EditNameViewModel(currentName: "Bia", service: service, userIDProvider: { "user-1" })

        viewModel.name = "Aline"
        let saved = await viewModel.save()

        #expect(!saved)
        #expect(!viewModel.didSave)
        #expect(viewModel.errorMessage != nil)
    }

    @Test("a failed account deletion keeps the user signed in")
    func deleteAccountFailure() async {
        let service = AccountServiceSpy()
        service.failsAccountCalls = true
        let viewModel = ProfileViewModel(service: service, userIDProvider: { "user-1" })

        await viewModel.deleteAccount(using: AuthSession(), coordinator: AppCoordinator())

        #expect(viewModel.deleteAccountFailed)
        #expect(service.deletedUserIDs == ["user-1"])
    }

    @Test("the filters keep the categories of their group and All keeps everything")
    func categoryFilterGroups() {
        #expect(CategoryFilter.all.includes(nil))
        #expect(CategoryFilter.parks.includes(.park))
        #expect(!CategoryFilter.parks.includes(.museum))
        #expect(!CategoryFilter.parks.includes(nil))
        #expect(CategoryFilter.eat.includes(.cafe))
        #expect(CategoryFilter.center.includes(.historic))
    }

    @Test("every category belongs to some filter chip")
    func everyCategoryIsReachable() {
        for category in ZanzarPlaceCategory.filterOptions {
            #expect(CategoryFilter.allCases.contains { $0 != .all && $0.includes(category) })
        }
    }

    @Test("check-in cards cycle through four tones")
    func tonesCycle() {
        #expect(ProfileCheckInTone.tone(at: 0) == .sand)
        #expect(ProfileCheckInTone.tone(at: 4) == .sand)
        #expect(ProfileCheckInTone.tone(at: 3) == .gold)
    }
}

private final class AccountServiceSpy: ProfileServicing, @unchecked Sendable {
    var failsAccountCalls = false
    private(set) var renamed: [String] = []
    private(set) var deletedUserIDs: [String] = []

    func fetchProfile(userID: String, limit: Int) async throws -> Profile {
        ProfileAccountTests.profile
    }

    func logout() async throws {}

    func updateName(userID: String, name: String) async throws {
        if failsAccountCalls { throw APIError.invalidRequest }
        renamed.append(name)
    }

    func deleteAccount(userID: String) async throws {
        deletedUserIDs.append(userID)
        if failsAccountCalls { throw APIError.invalidRequest }
    }
}
