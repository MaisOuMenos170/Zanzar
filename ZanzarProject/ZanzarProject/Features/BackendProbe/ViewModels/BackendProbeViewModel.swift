import Foundation
import Observation

@Observable
final class BackendProbeViewModel {
    private let service: BackendProbeServicing

    var healthCheck: HealthCheck?
    var createdUser: BackendUser?
    var fetchedUser: BackendUser?
    var isCheckingHealth = false
    var isCreatingUser = false
    var isFetchingUser = false
    var errorMessage: String?

    var baseURLDescription: String {
        BackendConfiguration.displayBaseURL
    }

    init(service: BackendProbeServicing = BackendProbeService()) {
        self.service = service
    }

    func checkHealth() async {
        isCheckingHealth = true
        errorMessage = nil
        defer { isCheckingHealth = false }

        do {
            healthCheck = try await service.fetchHealth()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func createTestUser() async {
        isCreatingUser = true
        errorMessage = nil
        defer { isCreatingUser = false }

        let suffix = UUID().uuidString.prefix(8).lowercased()
        let input = NewBackendUser(
            email: "ios-probe-\(suffix)@zanzar.test",
            name: "iOS Probe"
        )

        do {
            let user = try await service.createUser(input)
            createdUser = user
            fetchedUser = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func fetchCreatedUser() async {
        guard let userID = createdUser?.id else {
            errorMessage = String(localized: "backendProbe.fetchUser.missingUser.message")
            return
        }

        isFetchingUser = true
        errorMessage = nil
        defer { isFetchingUser = false }

        do {
            fetchedUser = try await service.fetchUser(id: userID)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
