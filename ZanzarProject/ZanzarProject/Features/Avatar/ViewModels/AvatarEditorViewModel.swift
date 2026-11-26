import Foundation
import Observation
import SwiftUI

@Observable
final class AvatarEditorViewModel {
    private let service: AvatarServicing
    private let userIDProvider: @Sendable () -> String?
    private var hasStoredAvatar = false
    /// The stored avatar could not be read, so the face on screen may not be the user's: saving would replace it.
    private var loadFailed = false

    var avatar: Avatar
    var selectedTab: AvatarEditorTab = .skin
    var isLoading = false
    var isSaving = false
    var saveError: String?

    init(
        service: AvatarServicing = AvatarService(),
        userIDProvider: @escaping @Sendable () -> String? = { AuthTokenStore.shared.userID },
        avatar: Avatar = .placeholder
    ) {
        self.service = service
        self.userIDProvider = userIDProvider
        self.avatar = avatar
    }

    var selectedValue: Int {
        value(for: selectedTab)
    }

    func value(for tab: AvatarEditorTab) -> Int {
        switch tab {
        case .skin: avatar.skin
        case .eyes: avatar.eyes
        case .eyebrow: avatar.eyebrow
        case .eyelash: avatar.eyelash
        case .hair: avatar.hair
        }
    }

    func select(_ value: Int) {
        let lowerBound = selectedTab.allowsNone ? Avatar.none : 1
        guard (lowerBound...selectedTab.optionCount).contains(value) else { return }
        switch selectedTab {
        case .skin: avatar.skin = value
        case .eyes: avatar.eyes = value
        case .eyebrow: avatar.eyebrow = value
        case .eyelash: avatar.eyelash = value
        case .hair: avatar.hair = value
        }
    }

    var backgroundColor: Color {
        get { Color(hex: avatar.background) ?? Color(hex: Avatar.defaultBackground) ?? .clear }
        set { avatar.background = newValue.hexString }
    }

    func load() async {
        guard !isLoading, let userID = userIDProvider() else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            if let stored = try await service.fetchAvatar(userID: userID) {
                avatar = stored
                hasStoredAvatar = true
            }
            loadFailed = false
        } catch {
            // The editor still opens on the default face, but `save()` will not overwrite the real avatar with it.
            loadFailed = true
            AppLog.avatar.error("Could not load the avatar to edit", error: error)
        }
    }

    func save() async -> Bool {
        guard !isSaving else { return false }
        guard let userID = userIDProvider() else {
            saveError = L10n.string("avatar.loadError.notAuthenticated")
            return false
        }

        isSaving = true
        saveError = nil
        defer { isSaving = false }

        if loadFailed {
            await load()
            // This save is dropped either way: the edits were made on the default face, not on the user's avatar.
            // If the retry worked, the real avatar is now on screen to edit again.
            saveError = loadFailed ? L10n.string("avatarEditor.loadError.message") : nil
            return false
        }

        do {
            if hasStoredAvatar {
                avatar = try await service.updateAvatar(userID: userID, avatar: avatar)
            } else {
                do {
                    avatar = try await service.createAvatar(userID: userID, avatar: avatar)
                } catch APIError.httpStatus(409, _) {
                    // The avatar was created in the meantime (for example by a retry): replace it instead.
                    avatar = try await service.updateAvatar(userID: userID, avatar: avatar)
                }
                hasStoredAvatar = true
            }
            return true
        } catch is CancellationError {
            return false
        } catch {
            saveError = APIError.rateLimitedMessage(for: error) ?? L10n.string("avatarEditor.saveError.message")
            return false
        }
    }
}
