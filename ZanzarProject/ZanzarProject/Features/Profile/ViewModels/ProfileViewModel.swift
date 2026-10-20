import Foundation
import Observation

@Observable
final class ProfileViewModel {
    private let service: ProfileServicing
    private let userIDProvider: @Sendable () -> String?
    private let checkInsLimit: Int
    private let now: () -> Date
    private var loadGeneration = 0
    private var lastLoadedAt: Date?
    /// Set when something outside this screen (a check-in) made the loaded profile outdated.
    private var isStale = false

    var profile: Profile?
    var isLoading = false
    var isSigningOut = false
    var errorMessage: String?
    var showsSignOutConfirmation = false
    var signOutFailed = false

    init(
        service: ProfileServicing = ProfileService(),
        userIDProvider: @escaping @Sendable () -> String? = { AuthTokenStore.shared.userID },
        checkInsLimit: Int = 4,
        now: @escaping () -> Date = { Date() }
    ) {
        self.service = service
        self.userIDProvider = userIDProvider
        self.checkInsLimit = checkInsLimit
        self.now = now
    }

    /// The next `load()` goes to the server even if the loaded profile is still within its freshness window.
    func markStale() {
        isStale = true
    }

    /// A failed refresh keeps the profile already on screen; only the first load surfaces an error.
    /// Re-entering the screen within `DataFreshness.screenMaxAge` keeps what is shown, unless the profile was
    /// marked stale or `force` is set (pull-to-refresh, retry).
    func load(force: Bool = false) async {
        if !force, !isStale, profile != nil, let lastLoadedAt,
           now().timeIntervalSince(lastLoadedAt) < DataFreshness.screenMaxAge / .seconds(1) {
            return
        }

        loadGeneration += 1
        let generation = loadGeneration

        isLoading = true
        errorMessage = nil
        defer {
            if generation == loadGeneration {
                isLoading = false
            }
        }

        // Without a user id the session is unusable; showing the previous profile would be stale data.
        guard let userID = userIDProvider() else {
            profile = nil
            errorMessage = String(localized: "profile.loadError.notAuthenticated")
            return
        }

        // Cleared before the request so a `markStale()` made while it runs is not lost.
        isStale = false
        do {
            let loadedProfile = try await service.fetchProfile(userID: userID, limit: checkInsLimit)
            guard generation == loadGeneration else { return }
            profile = loadedProfile
            lastLoadedAt = now()
        } catch is CancellationError {
            isStale = true
            return
        } catch {
            isStale = true
            // The server's message is never shown: the service already logged the details.
            guard generation == loadGeneration, profile == nil else { return }
            errorMessage = APIError.rateLimitedMessage(for: error) ?? String(localized: "profile.errorState.message")
        }
    }

    /// Revokes the token on the server first (the Bearer is still stored), then ends the local session.
    /// A server failure never traps the user: the local sign-out happens regardless (the token then stays
    /// valid on the server until it expires). The session and
    /// the navigation path are reset in the same main-actor turn so Welcome never renders a stale path.
    func signOut(using authSession: AuthSession, coordinator: AppCoordinator) async {
        guard !isSigningOut else { return }
        isSigningOut = true
        defer { isSigningOut = false }
        signOutFailed = false

        do {
            try await service.logout()
        } catch {
            AppLog.profile.warning("Continuing with local sign-out after server logout failure")
        }

        do {
            try authSession.signOut()
            coordinator.popToRoot()
        } catch {
            signOutFailed = true
        }
    }
}
