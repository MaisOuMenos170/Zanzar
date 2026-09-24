import Foundation
import Testing
@testable import ZanzarProject

@MainActor
@Suite("BackendProbeViewModel")
struct BackendProbeViewModelTests {
    @Test("Successful health check stores the status and clears loading")
    func successfulHealthCheck() async {
        let service = MockBackendProbeService()
        service.healthResult = .success(HealthCheck(status: "ok"))
        let viewModel = BackendProbeViewModel(service: service)

        await viewModel.checkHealth()

        #expect(viewModel.healthCheck == HealthCheck(status: "ok"))
        #expect(viewModel.isCheckingHealth == false)
        #expect(viewModel.errorMessage == nil)
    }

    @Test("Failed health check sets an error message")
    func failedHealthCheck() async {
        let service = MockBackendProbeService()
        service.healthResult = .failure(URLError(.notConnectedToInternet))
        let viewModel = BackendProbeViewModel(service: service)

        await viewModel.checkHealth()

        #expect(viewModel.healthCheck == nil)
        #expect(viewModel.isCheckingHealth == false)
        #expect(viewModel.errorMessage != nil)
    }

    @Test("Creating a test user stores the created user for later fetch")
    func createTestUser() async {
        let service = MockBackendProbeService()
        service.createUserResult = .success(
            BackendUser(id: "674abc123", email: "ios-probe@zanzar.test", name: "iOS Probe", role: .user)
        )
        let viewModel = BackendProbeViewModel(service: service)

        await viewModel.createTestUser()

        #expect(viewModel.createdUser?.id == "674abc123")
        #expect(viewModel.isCreatingUser == false)
        #expect(viewModel.errorMessage == nil)
    }

    @Test("Fetching a created user stores the fetched user")
    func fetchCreatedUser() async {
        let service = MockBackendProbeService()
        let createdUser = BackendUser(id: "674abc123", email: "ios-probe@zanzar.test", name: "iOS Probe", role: .user)
        service.createUserResult = .success(createdUser)
        service.fetchUserResult = .success(createdUser)
        let viewModel = BackendProbeViewModel(service: service)

        await viewModel.createTestUser()
        await viewModel.fetchCreatedUser()

        #expect(viewModel.fetchedUser == createdUser)
        #expect(viewModel.isFetchingUser == false)
        #expect(viewModel.errorMessage == nil)
    }
}

@MainActor
final class MockBackendProbeService: BackendProbeServicing {
    var healthResult: Result<HealthCheck, Error>?
    var createUserResult: Result<BackendUser, Error>?
    var fetchUserResult: Result<BackendUser, Error>?

    func fetchHealth() async throws -> HealthCheck {
        guard let healthResult else {
            fatalError("MockBackendProbeService.healthResult not configured")
        }
        return try healthResult.get()
    }

    func createUser(_ input: NewBackendUser) async throws -> BackendUser {
        guard let createUserResult else {
            fatalError("MockBackendProbeService.createUserResult not configured")
        }
        return try createUserResult.get()
    }

    func fetchUser(id: String) async throws -> BackendUser {
        guard let fetchUserResult else {
            fatalError("MockBackendProbeService.fetchUserResult not configured")
        }
        return try fetchUserResult.get()
    }
}
