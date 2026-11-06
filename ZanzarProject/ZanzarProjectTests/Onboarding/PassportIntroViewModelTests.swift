import Foundation
import Testing
@testable import ZanzarProject

@MainActor
@Suite("PassportIntroViewModel")
struct PassportIntroViewModelTests {
    private static let avatar = Avatar(skin: 3, eyes: 2, eyebrow: 5, eyelash: 4, hair: 7, background: "#112233")

    @Test("shows the avatar that was just saved and the registration's name without any request")
    func usesGivenValues() async {
        let profile = PassportProfileStub(name: "Outro")
        let viewModel = PassportIntroViewModel(
            avatar: Self.avatar,
            name: "Maria",
            profileService: profile,
            userIDProvider: { "user-1" }
        )

        await viewModel.loadNameIfNeeded()

        #expect(viewModel.avatar == Self.avatar)
        #expect(viewModel.name == "Maria")
        #expect(profile.fetchCount == 0)
    }

    @Test("a missing name is looked up in the profile")
    func looksUpMissingName() async {
        let viewModel = PassportIntroViewModel(
            avatar: Self.avatar,
            name: nil,
            profileService: PassportProfileStub(name: "Maria"),
            userIDProvider: { "user-1" }
        )

        await viewModel.loadNameIfNeeded()

        #expect(viewModel.name == "Maria")
    }

    @Test("a failed lookup leaves the name blank")
    func failedLookupKeepsBlank() async {
        let viewModel = PassportIntroViewModel(
            avatar: Self.avatar,
            name: nil,
            profileService: PassportProfileStub(name: nil),
            userIDProvider: { "user-1" }
        )

        await viewModel.loadNameIfNeeded()

        #expect(viewModel.name.isEmpty)
    }

    @Test("without a signed-in user nothing is requested")
    func noUser() async {
        let profile = PassportProfileStub(name: "Maria")
        let viewModel = PassportIntroViewModel(
            avatar: Self.avatar,
            name: nil,
            profileService: profile,
            userIDProvider: { nil }
        )

        await viewModel.loadNameIfNeeded()

        #expect(profile.fetchCount == 0)
        #expect(viewModel.name.isEmpty)
    }
}

private final class PassportProfileStub: ProfileServicing, @unchecked Sendable {
    let name: String?
    private(set) var fetchCount = 0

    init(name: String?) {
        self.name = name
    }

    func fetchProfile(userID: String, limit: Int) async throws -> Profile {
        fetchCount += 1
        guard let name else { throw APIError.httpStatus(500, message: nil) }
        return Profile(
            summary: ProfileSummary(name: name, checkInCount: 0, itineraryCount: 0, sealCount: 0),
            recentCheckIns: []
        )
    }

    func logout() async throws {}
}
