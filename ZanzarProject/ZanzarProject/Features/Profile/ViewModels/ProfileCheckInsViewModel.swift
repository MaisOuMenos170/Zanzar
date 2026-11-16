import Foundation
import Observation

/// Every check-in of the signed-in user, for "all check-ins" and "all seals".
@Observable
final class ProfileCheckInsViewModel {
    /// How many check-ins one request asks for: the most the backend allows (`limit` is capped at 20, above that
    /// it answers 400). It has no paging, so these lists show the 20 latest.
    static let fetchLimit = 20

    private(set) var checkIns: [ProfileCheckIn] = []
    private(set) var isLoading = false
    private(set) var hasLoaded = false
    private(set) var errorMessage: String?

    private let service: ProfileServicing
    private let userIDProvider: @Sendable () -> String?

    init(
        service: ProfileServicing = ProfileService(),
        userIDProvider: @escaping @Sendable () -> String? = { AuthTokenStore.shared.userID }
    ) {
        self.service = service
        self.userIDProvider = userIDProvider
    }

    /// A failed refresh keeps the check-ins already on screen.
    func load() async {
        guard let userID = userIDProvider() else {
            errorMessage = L10n.string("profile.loadError.notAuthenticated")
            hasLoaded = true
            return
        }
        isLoading = true
        defer {
            isLoading = false
            hasLoaded = true
        }
        do {
            checkIns = try await service.fetchProfile(userID: userID, limit: Self.fetchLimit).recentCheckIns
            errorMessage = nil
        } catch is CancellationError {
            return
        } catch {
            guard checkIns.isEmpty else { return }
            errorMessage = APIError.rateLimitedMessage(for: error) ?? L10n.string("profile.errorState.message")
        }
    }
}
