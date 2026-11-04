import Foundation
import Observation

/// When the app opens, tells the user about photos whose review finished since they last looked.
@Observable
final class PhotoStatusNoticeViewModel {
    private let service: UserPhotosServicing
    private let store: UserPhotoStatusStoring
    private let userIDProvider: @Sendable () -> String?

    init(
        service: UserPhotosServicing = UserPhotosService(),
        store: UserPhotoStatusStoring = UserDefaultsUserPhotoStatusStore(),
        userIDProvider: @escaping @Sendable () -> String? = { AuthTokenStore.shared.userID }
    ) {
        self.service = service
        self.store = store
        self.userIDProvider = userIDProvider
    }

    /// The message to show, or `nil` when nothing changed. The first run only records what is there.
    func checkForChanges() async -> String? {
        guard let userID = userIDProvider(),
              let photos = try? await service.fetchMyPhotos(userID: userID) else { return nil }
        let previous = store.lastSeenStatuses()
        let current = Dictionary(uniqueKeysWithValues: photos.map { ($0.id, $0.status.rawValue) })
        store.save(current)

        let changed = photos.filter { photo in
            guard let before = previous[photo.id] else { return false }
            return before != photo.status.rawValue && !photo.status.isUnderReview
        }
        let published = changed.filter { $0.status == .approved }.count
        let refused = changed.count - published
        switch (published, refused) {
        case (0, 0): return nil
        case (_, 0): return L10n.string("userPhotos.notice.published", published)
        case (0, _): return L10n.string("userPhotos.notice.notApproved", refused)
        default: return L10n.string("userPhotos.notice.mixed", published, refused)
        }
    }
}
