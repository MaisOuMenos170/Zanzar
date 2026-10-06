import SwiftUI
import Testing
@testable import ZanzarProject

@MainActor
@Suite("ProfileViewModel")
struct ProfileViewModelTests {
    @Test("exposes the summary and recent check-ins it was given")
    func exposesProvidedData() {
        let summary = ProfileSummary(name: "Bia", checkInCount: 2, itineraryCount: 1, sealCount: 0)
        let viewModel = ProfileViewModel(summary: summary, recentCheckIns: [])

        #expect(viewModel.summary == summary)
        #expect(viewModel.recentCheckIns.isEmpty)
    }

    @Test("sample data shows four recent check-ins")
    func sampleDataHasFourCheckIns() {
        let viewModel = ProfileViewModel()

        #expect(viewModel.recentCheckIns.count == 4)
    }

    @Test("signOut clears the authenticated session")
    func signOutClearsSession() throws {
        let store = InMemoryAuthTokenStore()
        let authSession = AuthSession(keychain: store)
        try authSession.signIn(token: "token")
        let viewModel = ProfileViewModel()

        viewModel.signOut(using: authSession, coordinator: AppCoordinator())

        #expect(!authSession.isAuthenticated)
        #expect(store.readToken() == nil)
        #expect(!viewModel.signOutFailed)
    }

    @Test("signOut resets the navigation path together with the session")
    func signOutResetsNavigationPath() throws {
        let authSession = AuthSession(keychain: InMemoryAuthTokenStore())
        try authSession.signIn(token: "token")
        let coordinator = AppCoordinator()
        coordinator.push(.login)
        let viewModel = ProfileViewModel()

        viewModel.signOut(using: authSession, coordinator: coordinator)

        #expect(coordinator.path.isEmpty)
    }

    @Test("a failed signOut keeps the session and the navigation path")
    func failedSignOutKeepsState() throws {
        let authSession = AuthSession(keychain: FailingDeleteTokenStore())
        try authSession.signIn(token: "token")
        let coordinator = AppCoordinator()
        coordinator.push(.login)
        let viewModel = ProfileViewModel()

        viewModel.signOut(using: authSession, coordinator: coordinator)

        #expect(viewModel.signOutFailed)
        #expect(authSession.isAuthenticated)
        #expect(!coordinator.path.isEmpty)
    }

    @Test("a new signOut attempt clears the previous failure flag")
    func newAttemptClearsPreviousFailure() throws {
        let store = FailingDeleteTokenStore()
        let authSession = AuthSession(keychain: store)
        try authSession.signIn(token: "token")
        let viewModel = ProfileViewModel()

        viewModel.signOut(using: authSession, coordinator: AppCoordinator())
        #expect(viewModel.signOutFailed)

        store.shouldFail = false
        viewModel.signOut(using: authSession, coordinator: AppCoordinator())

        #expect(!viewModel.signOutFailed)
        #expect(!authSession.isAuthenticated)
    }
}

/// Test double: `shouldFail` is only mutated from the main-actor test bodies, sequentially.
private final class FailingDeleteTokenStore: AuthTokenPersisting, @unchecked Sendable {
    struct DeleteFailure: Error {}

    var shouldFail = true

    func saveToken(_ token: String) throws {}
    func readToken() -> String? { nil }
    func deleteToken() throws {
        if shouldFail { throw DeleteFailure() }
    }
}
