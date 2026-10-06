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

        viewModel.signOut(using: authSession)

        #expect(!authSession.isAuthenticated)
        #expect(store.readToken() == nil)
        #expect(!viewModel.signOutFailed)
    }
}
