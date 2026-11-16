import Testing
@testable import ZanzarProject

@MainActor
@Suite("Profile account and filters")
struct ProfileAccountTests {
    fileprivate static let profile = Profile(
        summary: ProfileSummary(name: "Bia", checkInCount: 2, itineraryCount: 1, sealCount: 3),
        recentCheckIns: []
    )

    @Test("saving a new name sends it trimmed and shows it")
    func saveNameUpdatesProfile() async {
        let service = AccountServiceSpy()
        let viewModel = ProfileViewModel(service: service, userIDProvider: { "user-1" })
        await viewModel.load()

        viewModel.beginEditingName()
        #expect(viewModel.draftName == "Bia")
        viewModel.draftName = "  Aline "
        await viewModel.saveName()

        #expect(service.renamed == ["Aline"])
        #expect(viewModel.profile?.summary.name == "Aline")
        #expect(!viewModel.editNameFailed)
    }

    @Test("an empty or unchanged name is not sent")
    func saveNameIgnoresEmptyAndUnchanged() async {
        let service = AccountServiceSpy()
        let viewModel = ProfileViewModel(service: service, userIDProvider: { "user-1" })
        await viewModel.load()

        viewModel.draftName = "   "
        await viewModel.saveName()
        viewModel.draftName = "Bia"
        await viewModel.saveName()

        #expect(service.renamed.isEmpty)
    }

    @Test("a failed rename keeps the old name and flags the error")
    func saveNameFailureKeepsName() async {
        let service = AccountServiceSpy()
        service.failsAccountCalls = true
        let viewModel = ProfileViewModel(service: service, userIDProvider: { "user-1" })
        await viewModel.load()

        viewModel.draftName = "Aline"
        await viewModel.saveName()

        #expect(viewModel.profile?.summary.name == "Bia")
        #expect(viewModel.editNameFailed)
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
