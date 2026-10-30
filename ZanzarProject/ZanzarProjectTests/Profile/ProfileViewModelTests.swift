import SwiftUI
import os
import Testing
@testable import ZanzarProject

@MainActor
@Suite("ProfileViewModel")
struct ProfileViewModelTests {
    private static let profile = Profile(
        summary: ProfileSummary(name: "Bia", checkInCount: 2, itineraryCount: 1, sealCount: 3),
        recentCheckIns: [
            ProfileCheckIn(
                id: "p1|d1",
                placeID: "p1",
                placeName: "Parque",
                date: .now,
                photoURL: nil,
                sealCategory: .park,
                impressionTag: nil
            )
        ]
    )

    // MARK: - load

    @Test("load fetches the signed-in user's profile with the grid limit")
    func loadFetchesProfile() async {
        let service = MockProfileService(fetchResult: .success(Self.profile))
        let viewModel = ProfileViewModel(service: service, userIDProvider: { "user-1" })

        await viewModel.load()

        #expect(viewModel.profile == Self.profile)
        #expect(viewModel.errorMessage == nil)
        #expect(!viewModel.isLoading)
        #expect(service.lastUserID == "user-1")
        #expect(service.lastLimit == 4)
    }

    @Test("load without a signed-in user reports an error and skips the request")
    func loadWithoutUserID() async {
        let service = MockProfileService(fetchResult: .success(Self.profile))
        let viewModel = ProfileViewModel(service: service, userIDProvider: { nil })

        await viewModel.load()

        #expect(viewModel.profile == nil)
        #expect(viewModel.errorMessage != nil)
        #expect(service.fetchCount == 0)
    }

    @Test("a failed first load exposes a generic message, never the server's text")
    func firstLoadFailure() async {
        let service = MockProfileService(fetchResult: .failure(APIError.httpStatus(500, message: "boom")))
        let viewModel = ProfileViewModel(service: service, userIDProvider: { "user-1" })

        await viewModel.load()

        #expect(viewModel.profile == nil)
        #expect(viewModel.errorMessage == L10n.string("profile.errorState.message"))
        #expect(!viewModel.isLoading)
    }

    @Test("a failed refresh keeps the profile that is already on screen")
    func refreshFailureKeepsProfile() async {
        let service = MockProfileService(fetchResult: .success(Self.profile))
        let viewModel = ProfileViewModel(service: service, userIDProvider: { "user-1" })
        await viewModel.load()

        service.fetchResult = .failure(APIError.httpStatus(500, message: "boom"))
        await viewModel.load(force: true)

        #expect(viewModel.profile == Self.profile)
        #expect(viewModel.errorMessage == nil)
    }

    @Test("a refresh without a signed-in user drops the stale profile and reports an error")
    func refreshWithoutUserIDClearsProfile() async {
        let service = MockProfileService(fetchResult: .success(Self.profile))
        let userID = OSAllocatedUnfairLock<String?>(initialState: "user-1")
        let viewModel = ProfileViewModel(service: service, userIDProvider: { userID.withLock { $0 } })
        await viewModel.load()

        userID.withLock { $0 = nil }
        await viewModel.load(force: true)

        #expect(viewModel.profile == nil)
        #expect(viewModel.errorMessage == L10n.string("profile.loadError.notAuthenticated"))
        #expect(service.fetchCount == 1)
    }

    @Test("re-entering inside the freshness window keeps the profile; the window's end refetches")
    func loadRespectsFreshnessWindow() async {
        let service = MockProfileService(fetchResult: .success(Self.profile))
        let clock = TestClock()
        let viewModel = ProfileViewModel(service: service, userIDProvider: { "user-1" }, now: { clock.date })

        await viewModel.load()
        clock.advance(by: 89)
        await viewModel.load()
        #expect(service.fetchCount == 1)

        clock.advance(by: 2)
        await viewModel.load()
        #expect(service.fetchCount == 2)
    }

    @Test("force and a stale mark skip the freshness window")
    func forceAndStaleSkipTheWindow() async {
        let service = MockProfileService(fetchResult: .success(Self.profile))
        let viewModel = ProfileViewModel(service: service, userIDProvider: { "user-1" })
        await viewModel.load()

        await viewModel.load(force: true)
        #expect(service.fetchCount == 2)

        viewModel.markStale()
        await viewModel.load()
        #expect(service.fetchCount == 3)

        await viewModel.load()
        #expect(service.fetchCount == 3)
    }

    @Test("a refresh that fails keeps the profile marked stale so the next entry retries")
    func failedRefreshStaysStale() async {
        let service = MockProfileService(fetchResult: .success(Self.profile))
        let viewModel = ProfileViewModel(service: service, userIDProvider: { "user-1" })
        await viewModel.load()

        viewModel.markStale()
        service.fetchResult = .failure(URLError(.notConnectedToInternet))
        await viewModel.load()
        service.fetchResult = .success(Self.profile)
        await viewModel.load()

        #expect(service.fetchCount == 3)
    }

    @Test("a rate limited first load explains the wait instead of the generic message")
    func rateLimitedFirstLoad() async {
        let error = APIError.rateLimited(retryAfter: 300)
        let service = MockProfileService(fetchResult: .failure(error))
        let viewModel = ProfileViewModel(service: service, userIDProvider: { "user-1" })

        await viewModel.load()

        #expect(viewModel.errorMessage == error.errorDescription)
        #expect(viewModel.errorMessage != String(localized: "profile.errorState.message"))
    }

    // MARK: - signOut

    @Test("signOut revokes the token on the server before ending the local session")
    func signOutCallsServerFirst() async throws {
        let authSession = AuthSession(keychain: InMemoryAuthTokenStore())
        try authSession.signIn(accessToken: "token", refreshToken: "refresh")
        let service = MockProfileService()
        var wasAuthenticatedDuringLogout: Bool?
        service.onLogout = { wasAuthenticatedDuringLogout = authSession.isAuthenticated }
        let coordinator = AppCoordinator()
        coordinator.push(.login)
        let viewModel = ProfileViewModel(service: service)

        await viewModel.signOut(using: authSession, coordinator: coordinator)

        #expect(service.logoutCount == 1)
        #expect(wasAuthenticatedDuringLogout == true)
        #expect(!authSession.isAuthenticated)
        #expect(coordinator.path.isEmpty)
        #expect(!viewModel.signOutFailed)
        #expect(!viewModel.isSigningOut)
    }

    @Test("signOut still ends the local session when the server logout fails")
    func signOutContinuesAfterServerFailure() async throws {
        let authSession = AuthSession(keychain: InMemoryAuthTokenStore())
        try authSession.signIn(accessToken: "token", refreshToken: "refresh")
        let service = MockProfileService(logoutResult: .failure(URLError(.notConnectedToInternet)))
        let coordinator = AppCoordinator()
        coordinator.push(.login)
        let viewModel = ProfileViewModel(service: service)

        await viewModel.signOut(using: authSession, coordinator: coordinator)

        #expect(!authSession.isAuthenticated)
        #expect(coordinator.path.isEmpty)
        #expect(!viewModel.signOutFailed)
    }

    @Test("a Keychain failure keeps the session and the navigation path")
    func keychainFailureKeepsState() async throws {
        let authSession = AuthSession(keychain: FailingDeleteTokenStore())
        try authSession.signIn(accessToken: "token", refreshToken: "refresh")
        let coordinator = AppCoordinator()
        coordinator.push(.login)
        let viewModel = ProfileViewModel(service: MockProfileService())

        await viewModel.signOut(using: authSession, coordinator: coordinator)

        #expect(viewModel.signOutFailed)
        #expect(authSession.isAuthenticated)
        #expect(!coordinator.path.isEmpty)
    }

    @Test("a new attempt clears the previous Keychain failure flag")
    func newAttemptClearsPreviousFailure() async throws {
        let store = FailingDeleteTokenStore()
        let authSession = AuthSession(keychain: store)
        try authSession.signIn(accessToken: "token", refreshToken: "refresh")
        let viewModel = ProfileViewModel(service: MockProfileService())

        await viewModel.signOut(using: authSession, coordinator: AppCoordinator())
        #expect(viewModel.signOutFailed)

        store.shouldFail = false
        await viewModel.signOut(using: authSession, coordinator: AppCoordinator())

        #expect(!viewModel.signOutFailed)
        #expect(!authSession.isAuthenticated)
    }

    @Test("overlapping signOut calls send a single logout request")
    func overlappingSignOutCallsRunOnce() async throws {
        let authSession = AuthSession(keychain: InMemoryAuthTokenStore())
        try authSession.signIn(accessToken: "token", refreshToken: "refresh")
        let service = MockProfileService()
        service.suspendsDuringLogout = true
        let coordinator = AppCoordinator()
        let viewModel = ProfileViewModel(service: service)

        async let first: Void = viewModel.signOut(using: authSession, coordinator: coordinator)
        async let second: Void = viewModel.signOut(using: authSession, coordinator: coordinator)
        _ = await (first, second)

        #expect(service.logoutCount == 1)
    }
}

final class MockProfileService: ProfileServicing, @unchecked Sendable {
    var fetchResult: Result<Profile, Error>
    var logoutResult: Result<Void, Error>
    var suspendsDuringLogout = false
    var onLogout: (@MainActor () -> Void)?

    private(set) var fetchCount = 0
    private(set) var lastUserID: String?
    private(set) var lastLimit: Int?
    private(set) var logoutCount = 0

    init(
        fetchResult: Result<Profile, Error> = .failure(APIError.invalidResponse),
        logoutResult: Result<Void, Error> = .success(())
    ) {
        self.fetchResult = fetchResult
        self.logoutResult = logoutResult
    }

    func fetchProfile(userID: String, limit: Int) async throws -> Profile {
        fetchCount += 1
        lastUserID = userID
        lastLimit = limit
        return try fetchResult.get()
    }

    func logout() async throws {
        logoutCount += 1
        onLogout?()
        if suspendsDuringLogout {
            await Task.yield()
        }
        try logoutResult.get()
    }
}

/// Test double: `shouldFail` is only mutated from the main-actor test bodies, sequentially.
private final class FailingDeleteTokenStore: AuthTokenPersisting, @unchecked Sendable {
    struct DeleteFailure: Error {}

    var shouldFail = true

    func saveTokens(_ tokens: AuthTokens) throws {}
    func readTokens() -> AuthTokens? { nil }
    func deleteTokens() throws {
        if shouldFail { throw DeleteFailure() }
    }
}
