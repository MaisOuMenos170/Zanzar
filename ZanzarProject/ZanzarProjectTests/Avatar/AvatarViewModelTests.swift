import Foundation
import Testing
@testable import ZanzarProject

@MainActor
@Suite("AvatarViewModel")
struct AvatarViewModelTests {
    private static let avatar = Avatar(skin: 3, eyes: 2, eyebrow: 5, hair: 7)

    @Test("load fetches the signed-in user's avatar")
    func loadFetchesAvatar() async {
        let service = MockAvatarService(fetchResult: .success(Self.avatar))
        let viewModel = AvatarViewModel(service: service, userIDProvider: { "user-1" })

        await viewModel.load()

        #expect(viewModel.avatar == Self.avatar)
        #expect(viewModel.errorMessage == nil)
        #expect(!viewModel.hasNoAvatar)
        #expect(!viewModel.isLoading)
        #expect(service.lastUserID == "user-1")
    }

    @Test("a user without an avatar is not an error")
    func loadWithoutAvatar() async {
        let service = MockAvatarService(fetchResult: .success(nil))
        let viewModel = AvatarViewModel(service: service, userIDProvider: { "user-1" })

        await viewModel.load()

        #expect(viewModel.avatar == nil)
        #expect(viewModel.hasNoAvatar)
        #expect(viewModel.errorMessage == nil)
    }

    @Test("load without a signed-in user reports an error and skips the request")
    func loadWithoutUserID() async {
        let service = MockAvatarService(fetchResult: .success(Self.avatar))
        let viewModel = AvatarViewModel(service: service, userIDProvider: { nil })

        await viewModel.load()

        #expect(viewModel.avatar == nil)
        #expect(viewModel.errorMessage == L10n.string("avatar.loadError.notAuthenticated"))
        #expect(service.fetchCount == 0)
    }

    @Test("a failed load exposes a generic message, never the server's text")
    func loadFailure() async {
        let service = MockAvatarService(fetchResult: .failure(APIError.httpStatus(500, message: "boom")))
        let viewModel = AvatarViewModel(service: service, userIDProvider: { "user-1" })

        await viewModel.load()

        #expect(viewModel.avatar == nil)
        #expect(viewModel.errorMessage == L10n.string("avatar.errorState.message"))
        #expect(!viewModel.isLoading)
    }

    @Test("creating the placeholder avatar posts predefined options and shows the result")
    func createPlaceholder() async {
        let service = MockAvatarService(fetchResult: .success(nil), createResult: .success(.placeholder))
        let viewModel = AvatarViewModel(service: service, userIDProvider: { "user-1" })
        await viewModel.load()

        await viewModel.createPlaceholderAvatar()

        #expect(viewModel.avatar == .placeholder)
        #expect(!viewModel.hasNoAvatar)
        #expect(!viewModel.createFailed)
        #expect(!viewModel.isCreating)
        #expect(service.lastCreated == .placeholder)
        #expect(service.lastUserID == "user-1")
    }

    @Test("a failed create keeps the empty state and flags the failure")
    func createFailure() async {
        let service = MockAvatarService(
            fetchResult: .success(nil),
            createResult: .failure(APIError.httpStatus(500, message: "boom"))
        )
        let viewModel = AvatarViewModel(service: service, userIDProvider: { "user-1" })
        await viewModel.load()

        await viewModel.createPlaceholderAvatar()

        #expect(viewModel.avatar == nil)
        #expect(viewModel.hasNoAvatar)
        #expect(viewModel.createFailed)
        #expect(!viewModel.isCreating)
    }

    @Test("a 409 on create loads the avatar that already exists")
    func createConflictLoadsExisting() async {
        let service = MockAvatarService(
            fetchResult: .success(Self.avatar),
            createResult: .failure(APIError.httpStatus(409, message: nil))
        )
        let viewModel = AvatarViewModel(service: service, userIDProvider: { "user-1" })

        await viewModel.createPlaceholderAvatar()

        #expect(viewModel.avatar == Self.avatar)
        #expect(!viewModel.createFailed)
        #expect(service.fetchCount == 1)
    }

    @Test("the create request carries every layer")
    func encodesRequest() throws {
        let data = try JSONEncoder().encode(AvatarAPIRequest(avatar: Avatar(skin: 1, eyes: 2, eyebrow: 3, hair: 4)))
        let json = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Int])

        #expect(json == ["skin": 1, "eyes": 2, "eyebrow": 3, "hair": 4])
    }

    @Test("the response payload maps to the domain avatar")
    func mapsResponse() throws {
        let json = #"{ "skin": 1, "eyes": 6, "eyebrow": 4, "hair": 2 }"#
        let response = try JSONDecoder().decode(AvatarAPIResponse.self, from: Data(json.utf8))

        #expect(response.makeAvatar() == Avatar(skin: 1, eyes: 6, eyebrow: 4, hair: 2))
    }
}

final class MockAvatarService: AvatarServicing, @unchecked Sendable {
    var fetchResult: Result<Avatar?, Error>
    var createResult: Result<Avatar, Error>

    private(set) var fetchCount = 0
    private(set) var lastUserID: String?
    private(set) var lastCreated: Avatar?

    init(
        fetchResult: Result<Avatar?, Error> = .success(nil),
        createResult: Result<Avatar, Error> = .failure(APIError.invalidResponse)
    ) {
        self.fetchResult = fetchResult
        self.createResult = createResult
    }

    func createAvatar(userID: String, avatar: Avatar) async throws -> Avatar {
        lastUserID = userID
        lastCreated = avatar
        return try createResult.get()
    }

    func fetchAvatar(userID: String) async throws -> Avatar? {
        fetchCount += 1
        lastUserID = userID
        return try fetchResult.get()
    }
}
