import Foundation
import Observation

/// What the passport shows right after the avatar is saved: the avatar the backend just stored and the account's
/// name. The name comes from the registration response; only an account created another way (Sign in with Apple)
/// has to look it up.
@Observable
final class PassportIntroViewModel {
    private let profileService: ProfileServicing
    private let userIDProvider: @Sendable () -> String?

    /// The profile endpoint requires `limit` >= 1 even though only the name is used.
    static let profileCheckInsLimit = 1

    let avatar: Avatar
    private(set) var name: String

    init(
        avatar: Avatar,
        name: String?,
        profileService: ProfileServicing = ProfileService(),
        userIDProvider: @escaping @Sendable () -> String? = { AuthTokenStore.shared.userID }
    ) {
        self.avatar = avatar
        self.name = name ?? ""
        self.profileService = profileService
        self.userIDProvider = userIDProvider
    }

    /// Fills in a missing name; a failed lookup leaves it blank instead of blocking the intro.
    func loadNameIfNeeded() async {
        guard name.isEmpty, let userID = userIDProvider() else { return }
        do {
            name = try await profileService.fetchProfile(userID: userID, limit: Self.profileCheckInsLimit).summary.name
        } catch {
            AppLog.profile.error("Could not load the name for the passport", error: error)
        }
    }
}
